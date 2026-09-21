import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../models/economy.dart';

/// Central place for every sound/music trigger in the game.
///
/// Music (home theme, alternating battle themes) and one-shot SFX (turret
/// shots, mob deaths, barrier cues) are loaded and gated completely
/// independently of each other:
///
/// - Music loading is a single small future (3 mp3s + `bgm.initialize()`).
///   [playMenuMusic]/[playBattleMusicForWave] await *only* that.
/// - Each SFX player is created independently and played with a simple
///   null-check, no shared "ready" gate at all. If one hasn't finished
///   loading yet, that one trigger is silently skipped rather than blocking
///   — imperceptible in practice, and it means one slow/stuck SFX asset can
///   never take the home theme (or any other SFX) down with it. Previously
///   *everything* — music included — awaited one monolithic future that
///   built five pooled MediaPlayer-backed [AudioPool]s (up to 15 native
///   players) up front; if any single one of those hung, the home theme
///   would silently never start.
///
/// SFX also use `PlayerMode.lowLatency` (Android SoundPool, not MediaPlayer)
/// with one player per sound instead of a pooled `AudioPool`. `AudioPool`
/// defaults to the heavyweight `PlayerMode.mediaPlayer` (a real
/// prepare/start cycle over the platform channel per play, serialized
/// through a lock) — fine for occasional sounds, but the actual cause of
/// the audible delay and frame drops during rapid turret fire. lowLatency
/// mode is built for exactly this (quick, repeated, overlapping triggers);
/// a single player per sound is enough since SoundPool-backed playback
/// handles overlapping plays of the same sound natively.
///
/// Every call into the `audioplayers` plugin is still wrapped in [_guard]:
/// on a device/emulator with a broken audio backend, calls can throw well
/// after the call site returned, and since these fire constantly an
/// unguarded failure would spam unhandled-exception crashes through the
/// whole game loop.
class GameAudio {
  GameAudio._();
  static final GameAudio instance = GameAudio._();

  static const _musicFiles = ['main_theme.mp3', 'battle1.mp3', 'battle2.mp3'];

  Economy? _economy;
  bool _initialized = false;
  Future<void>? _musicLoadFuture;
  String? _currentMusic;
  bool _musicPausedByToggle = false;

  bool _lastMusicOn = true;
  double _lastMusicVolume = 7;

  AudioPlayer? _turretShotPlayer;
  AudioPlayer? _turretLaserPlayer;
  AudioPlayer? _turretBlasterPlayer;
  AudioPlayer? _mobDeathPlayer;
  AudioPlayer? _barrierLoweredPlayer;
  AudioPlayer? _barrierRisesPlayer;

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

  /// Builds each SFX player independently (rather than one sequential await
  /// chain) so a single slow/failing asset can't stall the others.
  Future<void> _loadSfx() async {
    await Future.wait([
      _guard(() async => _turretShotPlayer = await _createSfxPlayer('turret_shot.mp3')),
      _guard(() async => _turretLaserPlayer = await _createSfxPlayer('turret_laser.mp3')),
      _guard(() async => _turretBlasterPlayer = await _createSfxPlayer('turret_blaster.mp3')),
      _guard(() async => _mobDeathPlayer = await _createSfxPlayer('mob_death.mp3')),
      _guard(() async => _barrierLoweredPlayer = await _createSfxPlayer('barrier_lowered.mp3')),
      _guard(() async => _barrierRisesPlayer = await _createSfxPlayer('barrier_rises.mp3')),
    ]);
  }

  Future<AudioPlayer> _createSfxPlayer(String file) async {
    final player = AudioPlayer()..audioCache = FlameAudio.audioCache;
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setSource(AssetSource(file));
    return player;
  }

  Future<void> _playSfx(AudioPlayer? player) async {
    if (player == null) return;
    await player.setVolume(_sfxVolume);
    await player.resume();
  }

  Future<void> _musicReady() async {
    final future = _musicLoadFuture;
    if (future != null) await future;
  }

  double get _musicVolume =>
      (_economy?.musicOn ?? true) ? ((_economy?.musicVolume ?? 7) / 10).clamp(0.0, 1.0) : 0.0;
  double get _sfxVolume =>
      (_economy?.soundOn ?? true) ? ((_economy?.soundVolume ?? 7) / 10).clamp(0.0, 1.0) : 0.0;

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
  Future<void> playBattleMusicForWave(int wave) => _guard(() async {
    await _musicReady();
    final track = wave.isOdd ? 'battle1.mp3' : 'battle2.mp3';
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

  Future<void> playTurretShot(int tier) => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    final player = tier <= 2
        ? _turretShotPlayer
        : tier == 3
        ? _turretLaserPlayer
        : _turretBlasterPlayer;
    await _playSfx(player);
  });

  Future<void> playMobDeath() => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _playSfx(_mobDeathPlayer);
  });

  Future<void> playBarrierLowered() => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _playSfx(_barrierLoweredPlayer);
  });

  Future<void> playBarrierRises() => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _playSfx(_barrierRisesPlayer);
  });
}
