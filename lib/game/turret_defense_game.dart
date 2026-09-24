import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

import '../audio/game_audio.dart';
import '../game_assets.dart';
import '../models/achievements.dart';
import '../models/boss_types.dart';
import '../models/economy.dart';
import '../models/enemy_types.dart';
import '../models/turret_stats.dart';
import 'components/boss_component.dart';
import 'components/enemy_component.dart';
import 'components/fx_component.dart';
import 'components/projectile_component.dart';
import 'components/targetable.dart';
import 'components/turret_component.dart';
import 'grid.dart';

class TurretDefenseGame extends FlameGame {
  TurretDefenseGame({required this.economy});

  final Economy economy;
  final TurretGrid grid = TurretGrid();
  final math.Random _random = math.Random();

  // The background art bakes the dirt (mob field) and the metal tray
  // (turret grid backing) into one fixed-proportion image. The grid's
  // on-screen height changes with slotSize, so instead of stretching that
  // whole image we crop it into two pieces and resize each independently:
  // dirt fills everything above the grid, tray fills everything from the
  // grid up to the screen bottom. That keeps the mob field maximized and
  // the tray hugging the grid with no leftover gray space.
  static const double _traySplitFrac = 1552 / 2404;
  late SpriteComponent _dirtBg;
  late SpriteComponent _trayBg;
  late SpriteComponent _baseSprite;
  late List<Sprite> _dirtSprites;
  late List<Sprite> _traySprites;
  late Sprite _boltSprite;
  final List<SpriteComponent> _trayBolts = [];
  late Sprite _projectileSprite;

  // Pre-baked colored projectile art (see assets/images/shop/bullet_*.png —
  // the same files used as the shop preview image), keyed by the equipped
  // bullet_effect item's asset_key. Used instead of tinting the base
  // yellow-white sprite at runtime: a hue *rotation* can't meaningfully
  // recolor a near-white pixel (its brightest pixels stayed pale/yellow no
  // matter the target hue), so "red" looked washed out. Real colored art
  // has no such limit. New bullet_effect items whose asset_key isn't in
  // this map fall back to the old runtime hue-rotate tint (see
  // fireProjectileFromTurret) until matching art is added here.
  static const _bulletSkinAssetKeys = ['bullet_laser_red', 'bullet_plasma_purple', 'bullet_neon_green'];
  late Map<String, Sprite> _bulletSkinSprites;

  late List<Sprite> _hitFxFrames;
  late List<Sprite> _explosionFrames;
  final List<RectangleComponent> _slotVisuals = [];
  final List<({int row, int col})> _slotVisualCoords = [];

  double get baseLineY => grid.topY - 6;

  bool _waveActive = false;
  double _waveBreakTimer = 2.5;
  double _spawnTimer = 0;
  int _enemiesToSpawn = 0;
  int _enemiesSpawned = 0;
  int _enemiesResolved = 0;

  // --- Boss waves ----------------------------------------------------
  // A boss replaces the usual swarm every _bossWaveInterval waves after
  // _bossAfterWave clears: one big, slow, very tanky enemy instead of many
  // small ones, and *only* that boss — no regular spawns alongside it.
  // The boss doesn't consume a level number of its own: economy.wave stays
  // at the last cleared wave (e.g. 5) for the whole boss encounter, and
  // only advances to the next real wave (6) once the boss is dealt with —
  // see _tickWaves/_startWave. Movement speed is a single fixed constant
  // shared by *every* boss encounter — it never scales — only HP (and,
  // following from it, the reward for killing one) grows per encounter,
  // via a rough "how much DPS could a typical board deal around this
  // point" reference formula. This is a first-pass balance number meant
  // to be tuned from actual playtesting, not a simulation of real player
  // boards — see _referenceDpsForWave.
  static const int _bossAfterWave = 5;
  static const int _bossWaveInterval = 5;
  // Fast while off-screen (so the spawn-to-visible gap needed for it not
  // to look like it pops into existence doesn't feel dead), then this
  // slow constant once any part of it is actually on screen — see
  // BossComponent._currentSpeed.
  static const double _bossApproachSpeed = 40;
  static const double _bossSpeed = 4.5;
  static const double _bossFightSeconds = 30;
  static const double _bossHpGrowthPerEncounter = 0.6;
  // 0.9 * 0.45 (a further 55% cut requested after seeing the portrait
  // golem at 0.9 — it dominated the whole screen vertically).
  static const double _bossWidthFraction = 0.4;
  // A portrait-shaped boss (taller than wide) sized purely by
  // _bossWidthFraction would end up enormous vertically — its head alone
  // could fill the whole screen. Whichever of the two constraints (width
  // fraction of the canvas width, or this fraction of the canvas height)
  // yields the smaller box wins, so a tall boss's *height* gets capped
  // instead of its width ballooning unboundedly. A square boss (Plant1)
  // is unaffected by this in practice since its width-driven height
  // already stays well under this cap.
  static const double _bossMaxHeightFraction = 0.4;
  static const double _bossDamage = Economy.maxBaseHp * 0.35;
  double _bossBannerTimer = 0;
  bool _bossPending = false;
  bool _isCurrentWaveBoss = false;

  bool _shouldSpawnBossAfter(int clearedWave) =>
      clearedWave >= _bossAfterWave && (clearedWave - _bossAfterWave) % _bossWaveInterval == 0;

  // Classic ground mobs are 48x48 (EnemyComponent's default); a purchased
  // mob_skin renders 50% bigger than that — see _spawnEnemy.
  static const double _mobSkinSize = 48 * 1.5;

  @override
  Future<void> onLoad() async {
    // All battlefield layout math below assumes world-space (0,0) is the
    // top-left of the viewport, matching plain screen coordinates. Flame's
    // default viewfinder anchors world (0,0) to the viewport's *center*, so
    // without this every component would render shifted by half the canvas.
    camera.viewfinder.anchor = Anchor.topLeft;

    await GameAssets.init();

    final bgImages = await Future.wait([
      Flame.images.load('backgrounds/1.png'),
      Flame.images.load('backgrounds/2.png'),
      Flame.images.load('backgrounds/3.png'),
      Flame.images.load('backgrounds/4.png'),
    ]);
    _dirtSprites = bgImages.map(_cropDirt).toList();
    _traySprites = bgImages.map(_cropTray).toList();
    _boltSprite = await GameAssets.loadSprite('ui/bolt.png');
    _projectileSprite = await GameAssets.loadSprite('projectile/Projectile1.png');
    _bulletSkinSprites = {
      for (final key in _bulletSkinAssetKeys) key: await GameAssets.loadSprite('shop/$key.png'),
    };
    _hitFxFrames = await GameAssets.loadFrames('explosion2');
    _explosionFrames = await GameAssets.loadFrames('explosion1');

    _dirtBg = SpriteComponent(sprite: _dirtSprites[0], priority: -10);
    _trayBg = SpriteComponent(sprite: _traySprites[0], priority: -10);
    _baseSprite = SpriteComponent(
      sprite: await GameAssets.loadSprite('ground/Ground-Base.png'),
      priority: -5,
    );

    await world.addAll([_dirtBg, _trayBg, _baseSprite]);

    for (var i = 0; i < 4; i++) {
      final bolt = SpriteComponent(
        sprite: _boltSprite,
        size: Vector2.all(18),
        anchor: Anchor.center,
        priority: -4,
      );
      _trayBolts.add(bolt);
    }
    await world.addAll(_trayBolts);

    for (var r = 0; r < TurretGrid.rows; r++) {
      for (var c = 0; c < TurretGrid.cols; c++) {
        if (!TurretGrid.isUsable(r, c)) continue;
        final slotVisual = RectangleComponent(
          size: Vector2.all(TurretGrid.slotSize),
          anchor: Anchor.center,
          paint: Paint()
            ..color = const Color(0x33FFFFFF)
            ..style = PaintingStyle.fill,
        )..priority = -1;
        _slotVisuals.add(slotVisual);
        _slotVisualCoords.add((row: r, col: c));
        world.add(slotVisual);
      }
    }

    _relayout();
    // Arriving here only ever happens from the Home screen's tap-to-play,
    // so the run begins as soon as loading finishes — there's no in-canvas
    // menu step any more.
    startRun();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _relayout();
    }
  }

  Sprite _cropDirt(Image image) {
    final w = image.width.toDouble();
    final splitY = image.height * _traySplitFrac;
    return Sprite(image, srcPosition: Vector2.zero(), srcSize: Vector2(w, splitY));
  }

  Sprite _cropTray(Image image) {
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final splitY = h * _traySplitFrac;
    return Sprite(image, srcPosition: Vector2(0, splitY), srcSize: Vector2(w, h - splitY));
  }

  void _relayout() {
    grid.layout(size);

    final trayTop = grid.topY - 34;
    _dirtBg.size = Vector2(size.x, trayTop);
    _dirtBg.position = Vector2.zero();

    _trayBg.size = Vector2(size.x, size.y - trayTop);
    _trayBg.position = Vector2(0, trayTop);

    _baseSprite.size = Vector2(size.x, 34);
    _baseSprite.position = Vector2(0, grid.topY - 34);

    // Decorative bolts flank the two full-width grid rows on both sides,
    // in the side margins left over once the grid is centered horizontally.
    final leftX = grid.topLeft.x / 2;
    final rightX = size.x - grid.topLeft.x / 2;
    final rowYs = [grid.slotCenter(1, 0).y, grid.slotCenter(2, 0).y];
    final boltPositions = [
      Vector2(leftX, rowYs[0]),
      Vector2(rightX, rowYs[0]),
      Vector2(leftX, rowYs[1]),
      Vector2(rightX, rowYs[1]),
    ];
    for (var i = 0; i < _trayBolts.length; i++) {
      _trayBolts[i].position = boltPositions[i];
    }

    for (var i = 0; i < _slotVisuals.length; i++) {
      final coords = _slotVisualCoords[i];
      _slotVisuals[i].position = grid.slotCenter(coords.row, coords.col);
    }

    for (final turret in grid.allTurrets) {
      turret.position = grid.slotCenter(turret.row, turret.col);
    }
  }

  void startRun() {
    overlays.remove('lose');
    economy.resetRun();
    started = true;
    GameAudio.instance.playBattleMusicForWave(economy.wave);
    _dirtBg.sprite = _dirtSprites[0];
    _trayBg.sprite = _traySprites[0];
    for (final t in grid.allTurrets) {
      t.removeFromParent();
    }
    for (final e in world.children.whereType<Targetable>().toList()) {
      e.removeFromParent();
    }
    overlays.remove('bossFight');
    overlays.remove('bossDefeated');
    pendingAchievement = null;
    pendingAchievementIsRepeat = false;
    _bossBannerTimer = 0;
    for (var r = 0; r < TurretGrid.rows; r++) {
      for (var c = 0; c < TurretGrid.cols; c++) {
        grid.clear(r, c);
      }
    }
    _waveActive = false;
    _waveBreakTimer = 1.5;
    _enemiesSpawned = 0;
    _enemiesToSpawn = 0;
    _enemiesResolved = 0;
    _bossPending = false;
    _isCurrentWaveBoss = false;

    final startSlot = grid.firstEmptySlot();
    if (startSlot != null) {
      spawnTurretAt(startSlot.row, startSlot.col, 1);
    }
  }

  bool started = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
    if (economy.gameOver) {
      if (!overlays.isActive('lose')) {
        overlays.add('lose');
        GameAudio.instance.stopMusic();
        GameAudio.instance.playBarrierRises();
      }
      return;
    }
    if (!started) return;
    economy.tickAdCooldown(dt);
    _tickWaves(dt);

    if (_bossBannerTimer > 0) {
      _bossBannerTimer -= dt;
      if (_bossBannerTimer <= 0) {
        overlays.remove('bossFight');
      }
    }
  }

  void _tickWaves(double dt) {
    if (!_waveActive) {
      _waveBreakTimer -= dt;
      if (_waveBreakTimer <= 0) {
        _startWave();
      }
      return;
    }

    if (_isCurrentWaveBoss) {
      // Nothing to poll here — onBossKilled/onBossReachedBase (called
      // directly by BossComponent on death/reaching the base, not found
      // via a world.children scan) fully own the wave transition once the
      // boss is resolved, including the achievement-modal pause for a
      // kill. See continueAfterBossDefeat.
      return;
    }

    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _enemiesSpawned < _enemiesToSpawn) {
      _spawnEnemy();
      _enemiesSpawned++;
      _spawnTimer = _spawnInterval();
    }

    if (_enemiesSpawned >= _enemiesToSpawn &&
        world.children.whereType<Targetable>().isEmpty) {
      _waveActive = false;
      _waveBreakTimer = 3;
      if (_shouldSpawnBossAfter(economy.wave)) {
        // The boss doesn't consume a level number of its own — leave
        // economy.wave right where it is (e.g. 5) for the whole encounter;
        // _tickWaves' boss branch above is the one that finally calls
        // _advanceToNextWave once it's resolved.
        _bossPending = true;
      } else {
        _advanceToNextWave();
      }
    }
  }

  void _advanceToNextWave() {
    economy.nextWave();
    GameAudio.instance.playBattleMusicForWave(economy.wave);
    final bgIndex = ((economy.wave - 1) ~/ 3) % _dirtSprites.length;
    _dirtBg.sprite = _dirtSprites[bgIndex];
    _trayBg.sprite = _traySprites[bgIndex];
  }

  void _startWave() {
    _waveActive = true;
    _enemiesResolved = 0;
    _spawnTimer = 0;

    if (_bossPending) {
      _bossPending = false;
      _isCurrentWaveBoss = true;
      economy.setBossWave(true);
      // The whole wave is just the one boss — no timer-driven trickle of
      // regular spawns, so mark it fully "spawned" right away.
      _enemiesToSpawn = 1;
      _enemiesSpawned = 1;
      economy.setWaveProgress(0, 1);
      _spawnBoss();
      overlays.add('bossFight');
      _bossBannerTimer = 2.5;
    } else {
      _enemiesToSpawn = 4 + economy.wave * 2;
      _enemiesSpawned = 0;
      economy.setWaveProgress(0, _enemiesToSpawn);
    }
  }

  /// Very rough reference DPS "around wave [wave]": assumes a modest
  /// mid-game board (well under the 13-slot grid cap) of turrets at the
  /// average tier a typical run has reached by then. This is a starting
  /// point to balance boss HP against, not a simulation of any real
  /// player's board — expected to need tuning once this is actually
  /// played.
  double _referenceDpsForWave(int wave) {
    const referenceBoardSize = 6;
    final avgTier = (1 + wave * 0.35).clamp(1, TurretStats.maxTier.toDouble()).round();
    final stats = TurretStats(avgTier);
    return referenceBoardSize * (stats.damage / stats.fireInterval);
  }

  void _spawnBoss() {
    // economy.wave is still the just-cleared wave (5, 10, 15...) at this
    // point — see the "doesn't consume a level number" note above.
    final encounterIndex = (economy.wave - _bossAfterWave) ~/ _bossWaveInterval;
    final basicBossType = kBossTypes[encounterIndex % kBossTypes.length];
    final bossType = resolveBossType(basicBossType, economy.equippedBossSkinBySlot[basicBossType.slotId]);
    final encounterNumber = encounterIndex + 1;

    final dps = _referenceDpsForWave(economy.wave + 1);
    final hp = dps * _bossFightSeconds * (1 + (encounterNumber - 1) * _bossHpGrowthPerEncounter);

    // Not every boss's art is square — derive the other dimension from its
    // own aspect ratio instead of stretching it to fit a square box, and
    // pick whichever of the two candidate sizes (width-fraction-driven or
    // height-fraction-driven) comes out smaller, so a portrait boss's
    // height can't balloon past the canvas.
    final widthFromWidthFraction = size.x * _bossWidthFraction;
    final heightFromWidthFraction = widthFromWidthFraction / bossType.aspectRatio;
    final heightFromHeightFraction = size.y * _bossMaxHeightFraction;
    final double width;
    final double height;
    if (heightFromWidthFraction <= heightFromHeightFraction) {
      width = widthFromWidthFraction;
      height = heightFromWidthFraction;
    } else {
      height = heightFromHeightFraction;
      width = height * bossType.aspectRatio;
    }

    final boss = BossComponent(
      type: bossType,
      maxHp: hp,
      approachSpeed: _bossApproachSpeed,
      speed: _bossSpeed,
      damage: _bossDamage,
      reward: (hp * 0.08).round(),
      scoreReward: (hp * 0.5).round(),
      // Spawned just far enough above the screen to not be visible yet —
      // a bigger margin here directly means a longer wait (even at the
      // fast approach speed) before the player sees anything happen.
      position: Vector2(size.x / 2, -height * 1.05),
      size: Vector2(width, height),
    );
    world.add(boss);
  }

  /// The achievement figure just earned by killing a boss — read by
  /// BossDefeatedOverlay while that overlay is up, cleared once the
  /// player taps Continue.
  Achievement? pendingAchievement;

  /// Whether [pendingAchievement] was already owned before this kill (the
  /// roll can land on a duplicate) — BossDefeatedOverlay swaps its
  /// "unlocked" copy for an "already have it" one when this is true.
  bool pendingAchievementIsRepeat = false;

  void onBossKilled(BossComponent boss) {
    economy.addMoney(boss.reward);
    economy.addScore(boss.scoreReward);
    GameAudio.instance.playMobDeath();
    _resolveEnemy();

    // economy.wave is still the just-cleared wave here (see _spawnBoss's
    // own note) — the same formula recovers which boss (and which
    // repeat/encounter of it) this was, no need to search kBossTypes.
    final encounterIndex = (economy.wave - _bossAfterWave) ~/ _bossWaveInterval;
    final bossIndex = encounterIndex % kBossTypes.length;
    final achievement = rollAchievementForBoss(
      bossIndex: bossIndex,
      encounterNumber: encounterIndex + 1,
      nextRandom: _random.nextDouble,
    );
    final isNew = economy.unlockAchievement(achievement.id);
    pendingAchievement = achievement;
    pendingAchievementIsRepeat = !isNew;

    // Wave doesn't advance and the level number doesn't consume until the
    // player dismisses the achievement modal — see continueAfterBossDefeat.
    // Pausing (rather than just showing the overlay, like 'lose' does)
    // means closing/backgrounding the app here simply leaves the run
    // frozen at this exact point, nothing keeps ticking unseen.
    pauseEngine();
    overlays.add('bossDefeated');
  }

  /// Called by BossDefeatedOverlay's Continue button.
  void continueAfterBossDefeat() {
    overlays.remove('bossDefeated');
    pendingAchievement = null;
    pendingAchievementIsRepeat = false;
    _isCurrentWaveBoss = false;
    economy.setBossWave(false);
    // _startWave() left _waveActive true for the boss encounter (it never
    // goes through _tickWaves' normal enemiesSpawned/Targetable-empty
    // check). Without resetting it here, next frame's _tickWaves sees that
    // same stale "1/1, nothing left" bookkeeping, misreads it as a second
    // wave clearing, and calls _advanceToNextWave() again — silently
    // skipping a level number.
    _waveActive = false;
    _waveBreakTimer = 3;
    resumeEngine();
    _advanceToNextWave();
  }

  void onBossReachedBase(BossComponent boss) {
    economy.damageBase(boss.damage);
    GameAudio.instance.playBarrierLowered();
    spawnExplosion(Vector2(boss.position.x, baseLineY), size: Vector2(80, 80));
    _resolveEnemy();
    // Unlike a kill, reaching the base earns no achievement — proceed
    // straight to the next wave, same as a regular enemy would.
    _isCurrentWaveBoss = false;
    economy.setBossWave(false);
    // See the matching reset in continueAfterBossDefeat — same stale
    // _waveActive issue applies here too.
    _waveActive = false;
    _waveBreakTimer = 3;
    _advanceToNextWave();
  }

  double _spawnInterval() {
    return (1.1 - economy.wave * 0.015).clamp(0.32, 1.1);
  }

  void _spawnEnemy() {
    final pool = kEnemyTypes.where((t) => t.unlockWave <= economy.wave).toList();
    final type = pool[_random.nextInt(pool.length)];
    final wave = economy.wave;
    final hpMul = 1 + (wave - 1) * 0.16;
    final speedMul = (1 + (wave - 1) * 0.02).clamp(1.0, 1.7);

    const margin = 30.0;
    final spawnWidth = (size.x - margin * 2).clamp(10.0, double.infinity);
    final x = margin + _random.nextDouble() * spawnWidth;

    // A purchased mob_skin's art (see models/mob_skins.dart) reads as too
    // small at the classic beetles' 48x48 box, so ground mobs render 50%
    // bigger while a skin is equipped. Decided here (spawn time, where
    // `economy` is already in scope) rather than in EnemyComponent.onLoad
    // because the component's size has to be fixed at construction.
    final hasMobSkin = economy.equippedMobSkinByKind[type.kind.name] != null;
    final enemySize = hasMobSkin ? Vector2.all(_mobSkinSize) : null;

    final enemy = EnemyComponent(
      type: type,
      maxHp: type.baseHp * hpMul,
      speed: type.baseSpeed * speedMul,
      damage: type.baseDamage,
      reward: type.baseReward,
      position: Vector2(x, -30),
      size: enemySize,
    );
    world.add(enemy);
  }

  Targetable? findNearestEnemyInRange(Vector2 point, double range) {
    Targetable? nearest;
    var bestDist = range * range;
    for (final enemy in world.children.whereType<Targetable>()) {
      final d = enemy.position.distanceToSquared(point);
      if (d <= bestDist) {
        bestDist = d;
        nearest = enemy;
      }
    }
    return nearest;
  }

  void fireProjectileFromTurret(TurretComponent turret, Targetable target, double damage) {
    final muzzle = turret.position - Vector2(0, 22);
    final assetKey = economy.equippedBulletAssetKey;
    final skinSprite = assetKey != null ? _bulletSkinSprites[assetKey] : null;
    world.add(ProjectileComponent(
      sprite: skinSprite ?? _projectileSprite,
      // Only fall back to the runtime tint when there's no baked sprite
      // for this asset_key — never both, that would double-tint art
      // that's already the right color.
      tintHue: skinSprite == null ? economy.equippedBulletHue : null,
      target: target,
      damage: damage,
      position: muzzle,
    ));
    GameAudio.instance.playTurretShot(turret.tier);
  }

  void spawnHitFx(Vector2 position) {
    world.add(FxComponent(
      frames: _hitFxFrames,
      position: position,
      size: Vector2(34, 34),
      stepTime: 0.018,
    ));
  }

  void spawnExplosion(Vector2 position, {Vector2? size}) {
    world.add(FxComponent(
      frames: _explosionFrames,
      position: position,
      size: size ?? Vector2(50, 50),
      stepTime: 0.02,
    ));
  }

  void onEnemyReachedBase(EnemyComponent enemy) {
    economy.damageBase(enemy.damage);
    GameAudio.instance.playBarrierLowered();
    // A visible hit right where the mob crashed into the base line, on top
    // of BaseHealthBar's own shake/flash — the collision was previously
    // silent/invisible on the canvas itself.
    spawnExplosion(Vector2(enemy.position.x, baseLineY), size: Vector2(46, 46));
    _resolveEnemy();
  }

  void onEnemyKilled(EnemyComponent enemy) {
    economy.addMoney(enemy.reward);
    economy.addScore(enemy.type.scorePoints);
    GameAudio.instance.playMobDeath();
    _resolveEnemy();
  }

  void _resolveEnemy() {
    _enemiesResolved++;
    economy.setWaveProgress(_enemiesResolved, _enemiesToSpawn);
  }

  void spawnTurretAt(int row, int col, int tier) {
    final turret = TurretComponent(
      tier: tier,
      row: row,
      col: col,
      position: grid.slotCenter(row, col),
    );
    world.add(turret);
    grid.place(turret, row, col);
  }

  bool get hasEmptySlot => grid.firstEmptySlot() != null;

  /// Directly buys a turret starting at [level] (see the Buy menu — 1..10,
  /// levelBuyCost) rather than always tier 1. Returns false (spending
  /// nothing) if there's no empty slot or the player can't afford it, so
  /// the UI can show the right feedback.
  bool buyTurretAtLevel(int level) {
    final slot = grid.firstEmptySlot();
    if (slot == null) return false;
    final cost = levelBuyCost(level);
    if (!economy.spend(cost)) return false;
    economy.turretsPurchased++;
    spawnTurretAt(slot.row, slot.col, level);
    return true;
  }

  void claimFreeTurret() {
    final slot = grid.firstEmptySlot();
    if (slot == null) return;
    if (!economy.claimFreeTurret()) return;
    spawnTurretAt(slot.row, slot.col, 1);
  }

  void sellTurret(TurretComponent turret) {
    economy.addMoney(turret.stats.sellValue);
    grid.clear(turret.row, turret.col);
    turret.removeFromParent();
  }

  void handleTurretDrop(TurretComponent turret, Vector2 dropPosition, Vector2 fallbackPosition) {
    final targetSlot = grid.nearestSlot(dropPosition);
    final oldRow = turret.row;
    final oldCol = turret.col;

    if (targetSlot.row == oldRow && targetSlot.col == oldCol) {
      turret.position = grid.slotCenter(oldRow, oldCol);
      return;
    }

    final occupant = grid.at(targetSlot.row, targetSlot.col);
    if (occupant == null) {
      grid.clear(oldRow, oldCol);
      grid.place(turret, targetSlot.row, targetSlot.col);
    } else if (occupant.tier == turret.tier && turret.tier < TurretStats.maxTier) {
      grid.clear(oldRow, oldCol);
      grid.clear(targetSlot.row, targetSlot.col);
      occupant.removeFromParent();
      turret.removeFromParent();
      spawnTurretAt(targetSlot.row, targetSlot.col, turret.tier + 1);
    } else {
      turret.position = grid.slotCenter(oldRow, oldCol);
    }
  }
}
