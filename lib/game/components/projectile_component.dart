import 'dart:math' as math;
import 'dart:ui' show Canvas, Color, FilterQuality, Offset, StrokeCap;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Paint;

import '../../theme/hue_rotate.dart';
import '../turret_defense_game.dart';
import 'targetable.dart';

/// A homing shot fired by a turret. Homing (rather than a straight-line
/// shot) keeps low fire-rate tiers from feeling like they miss fast movers.
class ProjectileComponent extends SpriteComponent
    with HasGameReference<TurretDefenseGame> {
  final Targetable target;
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

  /// Animated shot effect (a turret skin's attack effect — see
  /// models/turret_skins.dart). When set it replaces the static [sprite]:
  /// the frames loop while the shot flies and are drawn pointing right, so
  /// the shot is rotated straight along its heading instead of the
  /// "sprite points up" +90° offset the static projectile art needs.
  final List<Sprite>? effectFrames;
  final Vector2? effectSize;

  /// When set, this shot is a spinning shuriken with a [trailColor] comet
  /// trail instead of the regular projectile (see models/turret_skins.dart).
  final Color? trailColor;
  final List<Vector2> _trail = [];
  double _spin = 0;
  static const int _trailLength = 9;

  // Field is private (_tintHue) but the constructor param must stay public
  // so other files can pass it — an initializing formal (this._tintHue)
  // would force callers to use the private name too.
  ProjectileComponent({
    required Sprite sprite,
    double? tintHue,
    required this.target,
    required this.damage,
    required Vector2 position,
    this.effectFrames,
    this.effectSize,
    this.trailColor,
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
    if (trailColor != null) {
      size = Vector2(22, 22);
      paint = Paint()..filterQuality = FilterQuality.medium;
      return;
    }
    final frames = effectFrames;
    if (frames != null && frames.isNotEmpty) {
      sprite = null;
      size = effectSize ?? Vector2(36, 18);
      add(SpriteAnimationComponent(
        animation: SpriteAnimation.spriteList(frames, stepTime: 0.03, loop: true),
        size: size,
      ));
      return;
    }
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
    if (distance < target.hitRadius) {
      target.takeDamage(damage);
      game.spawnHitFx(position.clone());
      removeFromParent();
      return;
    }

    delta.scale(1 / distance);
    if (trailColor != null) {
      _trail.add(position.clone());
      if (_trail.length > _trailLength) _trail.removeAt(0);
      _spin += dt * 20;
    }
    position += delta * speed * dt;
    if (trailColor == null) {
      angle = math.atan2(delta.y, delta.x) + (effectFrames != null ? 0 : math.pi / 2);
    }
  }

  @override
  void render(Canvas canvas) {
    final color = trailColor;
    if (color == null) {
      super.render(canvas);
      return;
    }
    final center = Offset(size.x / 2, size.y / 2);
    // Soft comet trail: oldest point faint and thin, newest brighter/thicker.
    final n = _trail.length;
    for (var i = 0; i < n; i++) {
      final from = _trail[i] - position;
      final to = (i + 1 < n ? _trail[i + 1] : position) - position;
      final t = (i + 1) / n;
      final paintLine = Paint()
        ..color = color.withValues(alpha: 0.5 * t)
        ..strokeWidth = 1.2 + 4.5 * t
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(from.x, from.y) + center,
        Offset(to.x, to.y) + center,
        paintLine,
      );
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_spin);
    canvas.translate(-center.dx, -center.dy);
    super.render(canvas);
    canvas.restore();
  }
}
