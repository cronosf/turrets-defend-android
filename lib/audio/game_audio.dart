import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../models/economy.dart';

/// Bundles a pooled SFX with the fallback duration used to release its
/// players back to the pool — see the doc comment on [GameAudio._buildSfxPool]
/// for why that's needed at all.
class _SfxPool {
  _SfxPool(this.pool, this.releaseAfter);

  final AudioPool pool;
  final Duration releaseAfter;
}

/// Central place for every sound/music trigger in the game. Music always
/// loops (home theme, or the alternating battle themes) and is only ever
/// fully stopped when a run ends; sound effects are one-shots gated by the
/// Sonido toggle/volume.
///
/// High-frequency sounds (turret shots especially — a tier-20 turret fires
/// every 0.25s, and there can be up to 10 of them) go through [AudioPool]s
/// instead of `FlameAudio.play`. Calling `FlameAudio.play` spins up a brand
/// new `AudioPlayer` (and native platform-channel player) on every call,
/// which under sustained rapid fire was the actual cause of the frame drops
/// reported around combat — not something a try/catch can paper over. Pools
/// pre-allocate and reuse a handful of players instead.
///
/// Every SFX pool is built with [PlayerMode.lowLatency]. `FlameAudio.createPool`
/// itself never sets a `playerMode`, so `AudioPool.create` was silently
/// defaulting to `PlayerMode.mediaPlayer` for every pool here — on Android
/// that's a full native `MediaPlayer` per pooled player (up to ~42 of them
/// across all pools), the same heavyweight object meant for long-form
/// music/video playback. That's what was actually behind "the game gets
/// slow the moment any sound effect plays" (present from wave 1, regardless
/// of fire rate, and unaffected by muting the music) — not a frequency
/// problem. `PlayerMode.lowLatency` maps to Android's `SoundPool`, built
/// for exactly this (many short, rapid-fire game SFX sharing one native
/// pool instead of one MediaPlayer each).
///
/// The tradeoff: `AudioPool.start()` only auto-returns a player to the pool
/// via `onPlayerComplete` when `playerMode != PlayerMode.lowLatency` (see
/// its source) — lowLatency players are never told to stop on their own,
/// so [_startPooled] schedules that release itself after each pool's own
/// clip length (queried once at load time via `getDuration()`).
///
/// Every call into the `audioplayers` plugin is still wrapped in [_guard]:
/// on a device/emulator with a broken audio backend, calls can hang and
/// eventually throw well after the call site returned, and since these fire
/// constantly an unguarded failure would spam unhandled-exception crashes
/// through the whole game loop.
class GameAudio {
  GameAudio._();
  static final GameAudio instance = GameAudio._();

  static const _musicFiles = ['main_theme.mp3', 'battle1.mp3', 'battle2.mp3'];

  // Matches FlameAudio's own default AudioContext (mixWithOthers) — we
  // build pools directly against AudioPool.create (rather than
  // FlameAudio.createPool) to be able to pass playerMode, so this has to
  // be replicated by hand.
  static final _sfxAudioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  // Safety margin added on top of each clip's own measured duration before
  // releasing its lowLatency player back to the pool.
  static const _releaseMargin = Duration(milliseconds: 60);
  static const _fallbackReleaseAfter = Duration(milliseconds: 800);

  Economy? _economy;
  bool _initialized = false;

  // Music and SFX load completely independently of each other (two
  // separate futures, not one shared chain): building the five SFX pools
  // below is the heaviest, most failure-prone part of startup (each one
  // spins up several native players), and previously a single slow/stuck
  // pool could silently keep the home theme from *ever* starting, since
  // everything awaited the same load future. Music now only waits on its
  // own much smaller, independent future.
  Future<void>? _musicLoadFuture;
  String? _currentMusic;
  bool _musicPausedByToggle = false;

  bool _lastMusicOn = true;
  double _lastMusicVolume = 7;

  _SfxPool? _turretShot;
  _SfxPool? _turretLaser;
  _SfxPool? _turretBlaster;
  _SfxPool? _warriorSplash;
  _SfxPool? _warriorDrown;
  _SfxPool? _warriorFlame;
  _SfxPool? _mobDeath;
  _SfxPool? _barrierLowered;
  _SfxPool? _barrierRises;

  /// Safe to call more than once (e.g. if a screen re-mounts) — only the
  /// first call binds the economy listener and kicks off loading.
  void init(Economy economy) {
    _economy = economy;
    if (_initialized) return;
    _initialized = true;
    _musicLoadFuture ??= _guard(_loadMusic);
    _guard(_loadSfx);
    _lastMusicOn = economy.musicOn;
    _lastMusicVolume = economy.musicVolume;
    economy.addListener(_onEconomyChanged);
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('GameAudio: ignoring audio error: $e');
    }
  }

  Future<void> _loadMusic() async {
    await FlameAudio.audioCache.loadAll(_musicFiles);
    await FlameAudio.bgm.initialize();
  }

  Future<_SfxPool> _buildSfxPool(
    String file, {
    required int minPlayers,
    required int maxPlayers,
  }) async {
    final pool = await AudioPool.create(
      source: AssetSource(file),
      audioCache: FlameAudio.audioCache,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      audioContext: _sfxAudioContext,
      playerMode: PlayerMode.lowLatency,
    );
    final duration = await pool.getDuration();
    final releaseAfter = duration == null
        ? _fallbackReleaseAfter
        : duration + _releaseMargin;
    return _SfxPool(pool, releaseAfter);
  }

  /// Each pool is built independently (rather than one sequential await
  /// chain) so a single slow/failing one can't stall the others — SFX
  /// methods below just null-check their own pool rather than awaiting a
  /// shared "ready" future.
  Future<void> _loadSfx() async {
    await Future.wait([
      _guard(() async {
        // maxPlayers 10, not 6 — this one (and blaster below) covers every
        // tier-4+ turret on a 13-slot board all firing near-simultaneously
        // late in an endless run; 6 meant the capacity guard in
        // _startPooled was skipping a shot's sound constantly by wave 20+.
        _turretShot = await _buildSfxPool(
          'turret_shot.mp3',
          minPlayers: 3,
          maxPlayers: 10,
        );
      }),
      _guard(() async {
        _turretLaser = await _buildSfxPool(
          'turret_laser.mp3',
          minPlayers: 3,
          maxPlayers: 10,
        );
      }),
      _guard(() async {
        _turretBlaster = await _buildSfxPool(
          'turret_blaster.mp3',
          minPlayers: 3,
          maxPlayers: 10,
        );
      }),
      _guard(() async {
        _warriorSplash = await _buildSfxPool('warrior_splash.wav', minPlayers: 3, maxPlayers: 10);
      }),
      _guard(() async {
        _warriorDrown = await _buildSfxPool('warrior_drown.wav', minPlayers: 2, maxPlayers: 6);
      }),
      _guard(() async {
        _warriorFlame = await _buildSfxPool('warrior_flame.wav', minPlayers: 3, maxPlayers: 8);
      }),
      _guard(() async {
        _mobDeath = await _buildSfxPool(
          'mob_death.mp3',
          minPlayers: 3,
          maxPlayers: 6,
        );
      }),
      _guard(() async {
        _barrierLowered = await _buildSfxPool(
          'barrier_lowered.mp3',
          minPlayers: 2,
          maxPlayers: 4,
        );
      }),
      _guard(() async {
        // Only ever fires once per run (game over), but still pooled —
        // see the class doc comment on why a bare FlameAudio.play call is
        // never safe to leave in, even for a rare one.
        _barrierRises = await _buildSfxPool(
          'barrier_rises.mp3',
          minPlayers: 1,
          maxPlayers: 2,
        );
      }),
    ]);
  }

  Future<void> _musicReady() async {
    final future = _musicLoadFuture;
    if (future != null) await future;
  }

  double get _musicVolume => (_economy?.musicOn ?? true)
      ? ((_economy?.musicVolume ?? 7) / 10).clamp(0.0, 1.0)
      : 0.0;
  double get _sfxVolume => (_economy?.soundOn ?? true)
      ? ((_economy?.soundVolume ?? 7) / 10).clamp(0.0, 1.0)
      : 0.0;

  void _onEconomyChanged() {
    final e = _economy;
    if (e == null) return;
    if (e.musicOn == _lastMusicOn && e.musicVolume == _lastMusicVolume) return;
    _lastMusicOn = e.musicOn;
    _lastMusicVolume = e.musicVolume;
    _guard(_applyMusicState);
  }

  Future<void> _applyMusicState() async {
    await _musicReady();
    final musicOn = _economy?.musicOn ?? true;

    if (!musicOn) {
      if (FlameAudio.bgm.isPlaying) {
        await FlameAudio.bgm.pause();
        _musicPausedByToggle = true;
      }
      return;
    }

    if (_musicPausedByToggle) {
      _musicPausedByToggle = false;
      await FlameAudio.bgm.resume();
      await FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
      return;
    }

    final track = _currentMusic;
    if (track == null) return;
    if (!FlameAudio.bgm.isPlaying) {
      // Music was toggled on after a track was already selected but never
      // actually started (it was off from the start).
      await FlameAudio.bgm.play(track, volume: _musicVolume);
    } else {
      await FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    }
  }

  /// Home screen theme — loops until the player enters a run.
  Future<void> playMenuMusic() => _guard(() async {
    await _musicReady();
    _currentMusic = 'main_theme.mp3';
    _musicPausedByToggle = false;
    if (_economy?.musicOn ?? true) {
      await FlameAudio.bgm.play('main_theme.mp3', volume: _musicVolume);
    }
  });

  /// Alternates battle_theme 1/2 per wave (odd waves -> theme 1, even -> 2).
  /// A no-op if that track is already the one playing — every wave
  /// transition used to call `FlameAudio.bgm.play` unconditionally, which
  /// does a full release+reload of the audio source every single time
  /// (see Bgm.play in the flame_audio package) even when the result is the
  /// exact same track already looping. That's both an audible stutter/cut
  /// at every wave boundary (the actual "music doesn't work well" symptom)
  /// and pointless native I/O on every wave.
  Future<void> playBattleMusicForWave(int wave) => _guard(() async {
    await _musicReady();
    final track = wave.isOdd ? 'battle1.mp3' : 'battle2.mp3';
    if (_currentMusic == track && FlameAudio.bgm.isPlaying) return;
    _currentMusic = track;
    _musicPausedByToggle = false;
    if (_economy?.musicOn ?? true) {
      await FlameAudio.bgm.play(track, volume: _musicVolume);
    }
  });

  Future<void> stopMusic() => _guard(() async {
    await _musicReady();
    _currentMusic = null;
    _musicPausedByToggle = false;
    await FlameAudio.bgm.stop();
  });

  /// Starts a pooled sound, but only if the pool actually has a player to
  /// give it — [AudioPool.maxPlayers] is *not* a hard cap: once every
  /// pooled player is busy, calling `.start()` again makes AudioPool spin
  /// up a brand-new native player on top of the pool (see its own doc
  /// comment — "there will still be new AudioPlayers created"), and that
  /// extra one is only ever `.release()`d, never `.dispose()`d, once it
  /// finishes — its native (platform-channel) side leaks. A high-tier
  /// turret board late in an endless run fires far more often than any
  /// pool's maxPlayers, so without this guard every burst past that limit
  /// permanently leaks another native player. Skipping the odd shot's
  /// sound under a dense barrage is inaudible; the leak wasn't.
  ///
  /// Because every pool now runs in [PlayerMode.lowLatency], AudioPool
  /// itself never learns a play finished (see the class doc comment), so
  /// the player has to be handed back manually after roughly its own clip
  /// length — otherwise every play stays "checked out" in `currentPlayers`
  /// forever and the capacity guard above starts rejecting sounds
  /// permanently after just [AudioPool.maxPlayers] plays, not just under
  /// sustained pressure.
  Future<void> _startPooled(_SfxPool? sfx) async {
    if (sfx == null) return;
    final pool = sfx.pool;
    // currentPlayers is @visibleForTesting in audioplayers — but it's the
    // only way to read "is this pool already at capacity" before calling
    // start(), and that's exactly the leak this guard exists to prevent
    // (see the doc comment above). No public equivalent is exposed.
    // ignore: invalid_use_of_visible_for_testing_member
    if (pool.currentPlayers.length >= pool.maxPlayers) return;
    final stop = await pool.start(volume: _sfxVolume);
    unawaited(Future.delayed(sfx.releaseAfter, stop));
  }

  Future<void> playTurretShot(int tier) => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    final sfx = tier <= 2
        ? _turretShot
        : tier == 3
        ? _turretLaser
        : _turretBlaster;
    await _startPooled(sfx);
  });

  /// Shot sound for the warrior turret skins (see TurretSkinType.attackSound)
  /// — replaces the regular tier-based turret shot sound.
  Future<void> playWarriorAttack(String file) => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _startPooled(
      file == 'warrior_flame.wav'
          ? _warriorFlame
          : file == 'warrior_drown.wav'
          ? _warriorDrown
          : _warriorSplash,
    );
  });

  Future<void> playMobDeath() => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _startPooled(_mobDeath);
  });

  Future<void> playBarrierLowered() => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _startPooled(_barrierLowered);
  });

  Future<void> playBarrierRises() => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _startPooled(_barrierRises);
  });
}
