import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Color, Colors, FontWeight, Paint, TextStyle;

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
  late final TextComponent _hpLabel;
  late final TextComponent _hpLabelShadow;

  // Periodic weapon-swing flourish while approaching — see
  // BossType.attackFramesDirectory's doc comment. null when this boss's
  // skin doesn't ship one (most don't), in which case the whole cycle
  // below is just skipped every frame.
  SpriteAnimation? _walkAnimation;
  SpriteAnimation? _attackAnimation;
  double _attackAnimDuration = 0;
  double _attackCycleTimer = 0;
  double _attackTimeLeft = 0;
  static const _attackCycleInterval = 2.0;
  static const _attackStepTime = 0.07;

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
    _walkAnimation = SpriteAnimation.spriteList(frames, stepTime: 0.12, loop: true);

    final attackDir = type.attackFramesDirectory;
    if (attackDir != null) {
      final attackFrames = await GameAssets.loadFrames(attackDir);
      if (attackFrames.isNotEmpty) {
        _attackAnimation = SpriteAnimation.spriteList(
          attackFrames,
          stepTime: _attackStepTime,
          loop: false,
        );
        _attackAnimDuration = attackFrames.length * _attackStepTime;
      }
    }

    _sprite = SpriteAnimationComponent(
      animation: _walkAnimation,
      size: size,
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_sprite);
    _fitSpriteToCurrentFrame();

    // Half as wide as the boss itself (centered) — at full boss width this
    // read as an oversized UI element rather than a health bar.
    final barWidth = size.x * 0.5;
    final barX = (size.x - barWidth) / 2;
    // The source art leaves empty padding above the actual artwork within
    // each frame (see BossType.artworkTopFraction) — anchoring to the raw
    // frame top left the bar floating visibly far above the plant itself.
    final barY = size.y * type.artworkTopFraction - 6;
    const barHeight = 10.0;
    _hpBarBg = RectangleComponent(
      position: Vector2(barX, barY),
      size: Vector2(barWidth, barHeight),
      paint: Paint()..color = Colors.black54,
    );
    _hpBarFill = RectangleComponent(
      position: Vector2(barX, barY),
      size: Vector2(barWidth, barHeight),
      paint: Paint()..color = const Color(0xFFE05A3A),
    );
    add(_hpBarBg);
    add(_hpBarFill);

    // Numeric "current/max" readout, same white-on-black-shadow treatment
    // as EnemyComponent's own HP label (see its doc comment for why white
    // reads fine on both this red bar and the mobs' green one) — bosses
    // render much bigger than a regular mob so this gets a bigger font.
    final hpLabelStyle = TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.bold,
    );
    final hpLabelPosition = Vector2(barX + barWidth / 2, barY + barHeight / 2);
    _hpLabelShadow = TextComponent(
      text: _hpLabelText,
      textRenderer: TextPaint(style: hpLabelStyle.copyWith(color: Colors.black)),
      anchor: Anchor.center,
      position: hpLabelPosition + Vector2(0.6, 0.6),
    );
    _hpLabel = TextComponent(
      text: _hpLabelText,
      textRenderer: TextPaint(style: hpLabelStyle),
      anchor: Anchor.center,
      position: hpLabelPosition,
    );
    add(_hpLabelShadow);
    add(_hpLabel);
  }

  String get _hpLabelText => '${hp.ceil()}/${maxHp.ceil()}';

  @override
  void update(double dt) {
    super.update(dt);
    if (_dead) return;

    position.y += _currentSpeed * dt;
    if (!_hasAppeared && _visibleTopY >= 0) {
      _hasAppeared = true;
    }
    _updateAttackCycle(dt);
    _fitSpriteToCurrentFrame();
    if (position.y >= game.baseLineY) {
      _dead = true;
      game.onBossReachedBase(this);
      removeFromParent();
    }
  }

  /// Keeps _sprite's rendered *height* pinned to the boss's own fixed
  /// [size] box, whatever frame is currently showing, instead of letting
  /// it shrink to "contain" a wider frame.
  ///
  /// The walk and attack animations' frames don't all share the same
  /// aspect ratio (the walk crop is tight and fairly consistent frame to
  /// frame; the attack pose swings a weapon out, so its own bbox varies
  /// far more — see BossType.attackFramesDirectory's doc comment).
  /// Stretching every frame to fill [size] (SpriteAnimationComponent's
  /// default) distorts it non-uniformly whenever the aspect doesn't match.
  /// The first fix for that — scaling each frame down to fit *within* the
  /// box, preserving its own aspect — avoided the distortion but traded it
  /// for a different shrink: the widest attack frame (weapon fully
  /// extended, near the end of the swing) has a much shorter, wider bbox
  /// than the walk crop, so fitting it by *width* left its height (and so
  /// the character) visibly shorter than while walking. Fitting by height
  /// instead keeps the character's own height pinned to exactly what it
  /// is while walking no matter which frame is showing — the tradeoff is
  /// that a wide frame's width can extend past the nominal box (the
  /// weapon swings a bit into the surrounding open lane instead of being
  /// squeezed to fit), which reads far better than the character itself
  /// changing size. A boss whose skin has no attack animation never
  /// actually changes frame aspect, so this is a no-op for it after the
  /// first call (width always comes out equal to [size].x).
  void _fitSpriteToCurrentFrame() {
    final frame = _sprite.animationTicker?.getSprite();
    if (frame == null) return;
    final frameSize = frame.srcSize;
    if (frameSize.x <= 0 || frameSize.y <= 0) return;
    final frameAspect = frameSize.x / frameSize.y;
    _sprite.size = Vector2(size.y * frameAspect, size.y);
  }

  /// Swaps the walk loop for the one-shot attack swing every
  /// [_attackCycleInterval] seconds while the boss is visible and
  /// approaching, then swaps back once it's played through — purely a
  /// visual flourish (see BossType.attackFramesDirectory), the boss keeps
  /// advancing at its normal speed the whole time either way. A no-op for
  /// every boss whose skin doesn't ship an attack animation.
  void _updateAttackCycle(double dt) {
    final attackAnimation = _attackAnimation;
    if (attackAnimation == null || !_hasAppeared) return;

    if (_attackTimeLeft > 0) {
      _attackTimeLeft -= dt;
      if (_attackTimeLeft <= 0) {
        _sprite.animation = _walkAnimation;
      }
      return;
    }

    _attackCycleTimer += dt;
    if (_attackCycleTimer >= _attackCycleInterval) {
      _attackCycleTimer = 0;
      _sprite.animation = attackAnimation;
      _attackTimeLeft = _attackAnimDuration;
    }
  }

  @override
  void takeDamage(double amount) {
    if (_dead) return;
    hp -= amount;
    _hpBarFill.size = Vector2(
      _hpBarBg.size.x * (hp / maxHp).clamp(0, 1),
      _hpBarBg.size.y,
    );
    final text = _hpLabelText;
    _hpLabel.text = text;
    _hpLabelShadow.text = text;
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
