import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
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

  late SpriteComponent _background;
  late SpriteComponent _baseSprite;
  late List<Sprite> _backgroundSprites;
  late Sprite _projectileSprite;
  late List<Sprite> _hitFxFrames;
  late List<Sprite> _explosionFrames;
  final List<RectangleComponent> _slotVisuals = [];

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

    _backgroundSprites = await Future.wait([
      GameAssets.loadSprite('backgrounds/1.png'),
      GameAssets.loadSprite('backgrounds/2.png'),
      GameAssets.loadSprite('backgrounds/3.png'),
      GameAssets.loadSprite('backgrounds/4.png'),
    ]);
    _projectileSprite = await GameAssets.loadSprite('projectile/Projectile1.png');
    _hitFxFrames = await GameAssets.loadFrames('explosion2');
    _explosionFrames = await GameAssets.loadFrames('explosion1');

    _background = SpriteComponent(sprite: _backgroundSprites[0], priority: -10);
    _baseSprite = SpriteComponent(
      sprite: await GameAssets.loadSprite('ground/Ground-Base.png'),
      priority: -5,
    );

    await world.addAll([_background, _baseSprite]);

    for (var i = 0; i < TurretGrid.rows * TurretGrid.cols; i++) {
      final slotVisual = RectangleComponent(
        size: Vector2.all(TurretGrid.slotSize),
        anchor: Anchor.center,
        paint: Paint()
          ..color = const Color(0x33FFFFFF)
          ..style = PaintingStyle.fill,
      )..priority = -1;
      _slotVisuals.add(slotVisual);
      world.add(slotVisual);
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

  void _relayout() {
    _background.size = size.clone();
    _background.position = Vector2.zero();

    grid.layout(size);

    _baseSprite.size = Vector2(size.x, 34);
    _baseSprite.position = Vector2(0, grid.topY - 34);

    for (var i = 0; i < _slotVisuals.length; i++) {
      final row = i ~/ TurretGrid.cols;
      final col = i % TurretGrid.cols;
      _slotVisuals[i].position = grid.slotCenter(row, col);
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
    _background.sprite = _backgroundSprites[0];
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
      final bgIndex = ((economy.wave - 1) ~/ 3) % _backgroundSprites.length;
      _background.sprite = _backgroundSprites[bgIndex];
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

  void buyTurret() {
    final slot = grid.firstEmptySlot();
    if (slot == null) return;
    final cost = turretBuyCost(economy.turretsPurchased);
    if (!economy.spend(cost)) return;
    economy.turretsPurchased++;
    spawnTurretAt(slot.row, slot.col, 1);
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
