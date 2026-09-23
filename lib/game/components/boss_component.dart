import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, Colors, Paint;

import '../../game_assets.dart';
import '../../models/boss_types.dart';
import '../turret_defense_game.dart';
import 'targetable.dart';

/// A boss: one big, slow, very tanky enemy that walks straight down the
/// lane, spawned alone in place of the usual swarm every few waves (see
/// TurretDefenseGame's boss-wave logic). Deliberately much simpler than
/// EnemyComponent — no sway, no per-type stat table, just the numbers the
/// spawner already worked out for this specific encounter.
class BossComponent extends PositionComponent
    with HasGameReference<TurretDefenseGame>, Targetable {
  final BossType type;
  final double maxHp;

  /// Fast approach speed used only while the boss is still fully
  /// off-screen — otherwise the huge spawn-to-screen gap needed to avoid
  /// it looking like it "pops into existence" made the wait before it's
  /// even visible feel dead. Once any part of it enters the screen it
  /// permanently switches to [speed], the real (slow) in-view pace.
  final double approachSpeed;
  final double speed;
  final double damage;
  final int reward;
  final int scoreReward;

  double hp;
  bool _dead = false;
  bool _hasAppeared = false;

  late final SpriteAnimationComponent _sprite;
  late final RectangleComponent _hpBarBg;
  late final RectangleComponent _hpBarFill;

  BossComponent({
    required this.type,
    required this.maxHp,
    required this.approachSpeed,
    required this.speed,
    required this.damage,
    required this.reward,
    required this.scoreReward,
    required Vector2 position,
    required Vector2 size,
  })  : hp = maxHp,
        super(position: position, size: size, anchor: Anchor.center);

  double get _currentSpeed => _hasAppeared ? speed : approachSpeed;

  /// World Y of the topmost actually-visible pixel (the leading edge as
  /// the boss walks down) — the frame's raw bounding box includes a lot
  /// of transparent padding above the real artwork (see
  /// BossType.artworkTopFraction), so using the box edge here would slow
  /// the boss down well before any of it is actually on screen.
  double get _visibleTopY => position.y - size.y / 2 + size.y * type.artworkTopFraction;

  @override
  bool get isDead => _dead;

  // A shot should have to actually reach into the boss's body, not just
  // its far outer edge, but "dead center" would make shots from the sides
  // look like they fly straight through — a third of its width is a
  // reasonable middle ground to tune from.
  @override
  double get hitRadius => size.x * 0.35;

  @override
  Future<void> onLoad() async {
    final framesDir = type.walkFramesDirectory;
    final frames = framesDir != null
        ? await GameAssets.loadFrames(framesDir)
        : await GameAssets.loadSheetRow(
            type.walkSheetPath!,
            frameWidth: type.frameSize!,
            frameHeight: type.frameSize!,
            row: type.directionRow!,
            columns: type.frameCount!,
          );
    _sprite = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(frames, stepTime: 0.12, loop: true),
      size: size,
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_sprite);

    // Half as wide as the boss itself (centered) — at full boss width this
    // read as an oversized UI element rather than a health bar.
    final barWidth = size.x * 0.5;
    final barX = (size.x - barWidth) / 2;
    // The source art leaves empty padding above the actual artwork within
    // each frame (see BossType.artworkTopFraction) — anchoring to the raw
    // frame top left the bar floating visibly far above the plant itself.
    final barY = size.y * type.artworkTopFraction - 6;
    _hpBarBg = RectangleComponent(
      position: Vector2(barX, barY),
      size: Vector2(barWidth, 7),
      paint: Paint()..color = Colors.black54,
    );
    _hpBarFill = RectangleComponent(
      position: Vector2(barX, barY),
      size: Vector2(barWidth, 7),
      paint: Paint()..color = const Color(0xFFE05A3A),
    );
    add(_hpBarBg);
    add(_hpBarFill);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_dead) return;

    position.y += _currentSpeed * dt;
    if (!_hasAppeared && _visibleTopY >= 0) {
      _hasAppeared = true;
    }
    if (position.y >= game.baseLineY) {
      _dead = true;
      game.onBossReachedBase(this);
      removeFromParent();
    }
  }

  @override
  void takeDamage(double amount) {
    if (_dead) return;
    hp -= amount;
    _hpBarFill.size = Vector2(_hpBarBg.size.x * (hp / maxHp).clamp(0, 1), 7);
    if (hp <= 0) _die();
  }

  void _die() {
    if (_dead) return;
    _dead = true;
    game.onBossKilled(this);
    game.spawnExplosion(position.clone(), size: Vector2(size.x * 0.7, size.x * 0.7));
    removeFromParent();
  }
}
