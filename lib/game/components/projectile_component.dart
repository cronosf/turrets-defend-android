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

  /// Only set when the caller couldn't find a pre-baked colored sprite for
  /// the equipped bullet effect (e.g. a new shop item added without game
  /// art yet) — a runtime hue *rotation* is a poor substitute for real
  /// colored art when the base sprite's brightest pixels are already
  /// near-white (rotating a desaturated color barely changes it, which is
  /// why "red" used to still look pale/yellow), but it's a reasonable
  /// fallback so a new bullet_effect item isn't colorless until art catches
  /// up.
  final double? _tintHue;

  // Field is private (_tintHue) but the constructor param must stay public
  // so other files can pass it — an initializing formal (this._tintHue)
  // would force callers to use the private name too.
  ProjectileComponent({
    required Sprite sprite,
    double? tintHue,
    required this.target,
    required this.damage,
    required Vector2 position,
  })  : _tintHue = tintHue, // ignore: prefer_initializing_formals
        super(
          sprite: sprite,
          position: position,
          size: Vector2(14, 14),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final hue = _tintHue;
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
