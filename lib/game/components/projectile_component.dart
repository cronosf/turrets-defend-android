import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Paint;

import '../../theme/hue_rotate.dart';
import '../turret_defense_game.dart';
import 'enemy_component.dart';

/// A homing shot fired by a turret. Homing (rather than a straight-line
/// shot) keeps low fire-rate tiers from feeling like they miss fast movers.
class ProjectileComponent extends SpriteComponent
    with HasGameReference<TurretDefenseGame> {
  final EnemyComponent target;
  final double damage;
  static const double speed = 460;

  ProjectileComponent({
    required Sprite sprite,
    required this.target,
    required this.damage,
    required Vector2 position,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(14, 14),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final hue = game.economy.equippedBulletHue;
    if (hue != null) {
      paint = Paint()..colorFilter = hueRotateFilter(hue, baseHueTurns: kProjectileBaseHueTurns);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!target.isMounted || target.isDead) {
      removeFromParent();
      return;
    }

    final delta = target.position - position;
    final distance = delta.length;
    if (distance < 14) {
      target.takeDamage(damage);
      game.spawnHitFx(position.clone());
      removeFromParent();
      return;
    }

    delta.scale(1 / distance);
    position += delta * speed * dt;
    angle = math.atan2(delta.y, delta.x) + math.pi / 2;
  }
}
