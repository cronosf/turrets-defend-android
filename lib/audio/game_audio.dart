import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../models/economy.dart';

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
/// Every call into the `audioplayers` plugin is still wrapped in [_guard]:
/// on a device/emulator with a broken audio backend, calls can hang and
/// eventually throw well after the call site returned, and since these fire
/// constantly an unguarded failure would spam unhandled-exception crashes
/// through the whole game loop.
class GameAudio {
  GameAudio._();
  static final GameAudio instance = GameAudio._();

  static const _files = [
    'main_theme.mp3',
    'battle1.mp3',
    'battle2.mp3',
    'turret_shot.mp3',
    'turret_laser.mp3',
    'turret_blaster.mp3',
    'mob_death.mp3',
    'barrier_lowered.mp3',
    'barrier_rises.mp3',
  ];

  Economy? _economy;
  bool _initialized = false;
  Future<void>? _loadFuture;
  String? _currentMusic;
  bool _musicPausedByToggle = false;

  bool _lastMusicOn = true;
  double _lastMusicVolume = 7;

  AudioPool? _turretShotPool;
  AudioPool? _turretLaserPool;
  AudioPool? _turretBlasterPool;
  AudioPool? _mobDeathPool;
  AudioPool? _barrierLoweredPool;

  /// Safe to call more than once (e.g. if a screen re-mounts) — only the
  /// first call binds the economy listener and kicks off loading.
  void init(Economy economy) {
    _economy = economy;
    if (_initialized) return;
    _initialized = true;
    _loadFuture ??= _guard(_load);
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

  Future<void> _load() async {
    await FlameAudio.audioCache.loadAll(_files);
    await FlameAudio.bgm.initialize();
    _turretShotPool = await FlameAudio.createPool('turret_shot.mp3', minPlayers: 3, maxPlayers: 6);
    _turretLaserPool = await FlameAudio.createPool(
      'turret_laser.mp3',
      minPlayers: 3,
      maxPlayers: 6,
    );
    _turretBlasterPool = await FlameAudio.createPool(
      'turret_blaster.mp3',
      minPlayers: 3,
      maxPlayers: 6,
    );
    _mobDeathPool = await FlameAudio.createPool('mob_death.mp3', minPlayers: 3, maxPlayers: 6);
    _barrierLoweredPool = await FlameAudio.createPool(
      'barrier_lowered.mp3',
      minPlayers: 2,
      maxPlayers: 4,
    );
  }

  Future<void> _ready() async {
    final future = _loadFuture;
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
    await _ready();
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
    await _ready();
    _currentMusic = 'main_theme.mp3';
    _musicPausedByToggle = false;
    if (_economy?.musicOn ?? true) {
      await FlameAudio.bgm.play('main_theme.mp3', volume: _musicVolume);
    }
  });

  /// Alternates battle_theme 1/2 per wave (odd waves -> theme 1, even -> 2).
  Future<void> playBattleMusicForWave(int wave) => _guard(() async {
    await _ready();
    final track = wave.isOdd ? 'battle1.mp3' : 'battle2.mp3';
    _currentMusic = track;
    _musicPausedByToggle = false;
    if (_economy?.musicOn ?? true) {
      await FlameAudio.bgm.play(track, volume: _musicVolume);
    }
  });

  Future<void> stopMusic() => _guard(() async {
    await _ready();
    _currentMusic = null;
    _musicPausedByToggle = false;
    await FlameAudio.bgm.stop();
  });

  Future<void> playTurretShot(int tier) => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _ready();
    final pool = tier <= 2
        ? _turretShotPool
        : tier == 3
        ? _turretLaserPool
        : _turretBlasterPool;
    await pool?.start(volume: _sfxVolume);
  });

  Future<void> playMobDeath() => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _ready();
    await _mobDeathPool?.start(volume: _sfxVolume);
  });

  Future<void> playBarrierLowered() => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _ready();
    await _barrierLoweredPool?.start(volume: _sfxVolume);
  });

  Future<void> playBarrierRises() => _guard(() async {
    if (!(_economy?.soundOn ?? true)) return;
    await _ready();
    await FlameAudio.play('barrier_rises.mp3', volume: _sfxVolume);
  });
}
