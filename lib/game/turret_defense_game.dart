import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

import '../audio/game_audio.dart';
import '../game_assets.dart';
import '../models/economy.dart';
import '../models/enemy_types.dart';
import '../models/turret_stats.dart';
import 'components/enemy_component.dart';
import 'components/fx_component.dart';
import 'components/projectile_component.dart';
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
    for (final e in world.children.whereType<EnemyComponent>().toList()) {
      e.removeFromParent();
    }
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
  }

  void _tickWaves(double dt) {
    if (!_waveActive) {
      _waveBreakTimer -= dt;
      if (_waveBreakTimer <= 0) {
        _startWave();
      }
      return;
    }

    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _enemiesSpawned < _enemiesToSpawn) {
      _spawnEnemy();
      _enemiesSpawned++;
      _spawnTimer = _spawnInterval();
    }

    if (_enemiesSpawned >= _enemiesToSpawn &&
        world.children.whereType<EnemyComponent>().isEmpty) {
      _waveActive = false;
      _waveBreakTimer = 3;
      economy.nextWave();
      GameAudio.instance.playBattleMusicForWave(economy.wave);
      final bgIndex = ((economy.wave - 1) ~/ 3) % _dirtSprites.length;
      _dirtBg.sprite = _dirtSprites[bgIndex];
      _trayBg.sprite = _traySprites[bgIndex];
    }
  }

  void _startWave() {
    _waveActive = true;
    _enemiesToSpawn = 4 + economy.wave * 2;
    _enemiesSpawned = 0;
    _enemiesResolved = 0;
    _spawnTimer = 0;
    economy.setWaveProgress(0, _enemiesToSpawn);
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

    final enemy = EnemyComponent(
      type: type,
      maxHp: type.baseHp * hpMul,
      speed: type.baseSpeed * speedMul,
      damage: type.baseDamage,
      reward: type.baseReward,
      position: Vector2(x, -30),
    );
    world.add(enemy);
  }

  EnemyComponent? findNearestEnemyInRange(Vector2 point, double range) {
    EnemyComponent? nearest;
    var bestDist = range * range;
    for (final enemy in world.children.whereType<EnemyComponent>()) {
      final d = enemy.position.distanceToSquared(point);
      if (d <= bestDist) {
        bestDist = d;
        nearest = enemy;
      }
    }
    return nearest;
  }

  void fireProjectileFromTurret(TurretComponent turret, EnemyComponent target, double damage) {
    final muzzle = turret.position - Vector2(0, 22);
    world.add(ProjectileComponent(
      sprite: _projectileSprite,
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
