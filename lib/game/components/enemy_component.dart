import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../game_assets.dart';
import '../../models/enemy_types.dart';
import '../turret_defense_game.dart';

/// A single enemy walking/flying down the battlefield toward the base.
class EnemyComponent extends PositionComponent
    with HasGameReference<TurretDefenseGame> {
  final EnemyType type;
  final double maxHp;
  final double speed;
  final double damage;
  final int reward;

  double hp;
  bool _dead = false;
  double _swayTime = 0;
  final double _swayPhase;

  late final SpriteAnimationComponent _sprite;
  late final RectangleComponent _hpBarBg;
  late final RectangleComponent _hpBarFill;

  EnemyComponent({
    required this.type,
    required this.maxHp,
    required this.speed,
    required this.damage,
    required this.reward,
    required Vector2 position,
  })  : hp = maxHp,
        _swayPhase = math.Random().nextDouble() * math.pi * 2,
        super(position: position, size: Vector2(48, 48), anchor: Anchor.center);

  bool get isDead => _dead;

  @override
  Future<void> onLoad() async {
    final frames = await GameAssets.loadFrames(type.assetDir);
    _sprite = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(
        frames.isEmpty ? [await GameAssets.loadSprite('ground/Ground-Base.png')] : frames,
        stepTime: 0.045,
        loop: true,
      ),
      size: size,
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_sprite);

    _hpBarBg = RectangleComponent(
      position: Vector2(0, -8),
      size: Vector2(size.x, 5),
      paint: Paint()..color = Colors.black54,
    );
    _hpBarFill = RectangleComponent(
      position: Vector2(0, -8),
      size: Vector2(size.x, 5),
      paint: Paint()..color = Colors.greenAccent,
    );
    add(_hpBarBg);
    add(_hpBarFill);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_dead) return;

    position.y += speed * dt;
    if (type.kind == EnemyKind.fly) {
      _swayTime += dt;
      position.x += math.sin(_swayTime * 2.4 + _swayPhase) * 22 * dt;
    }

    if (position.y >= game.baseLineY) {
      _dead = true;
      game.onEnemyReachedBase(this);
      removeFromParent();
    }
  }

  void takeDamage(double amount) {
    if (_dead) return;
    hp -= amount;
    _hpBarFill.size = Vector2(size.x * (hp / maxHp).clamp(0, 1), 5);
    if (hp <= 0) {
      _die();
    }
  }

  void _die() {
    if (_dead) return;
    _dead = true;
    game.onEnemyKilled(this);
    game.spawnExplosion(position.clone(), size: Vector2(56, 56));
    removeFromParent();
  }
}
