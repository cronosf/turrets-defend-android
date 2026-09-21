import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Colors, FontWeight, TextStyle;

import '../../game_assets.dart';
import '../../l10n/app_strings.dart';
import '../../models/turret_stats.dart';
import '../turret_defense_game.dart';

/// A turret sitting in a grid slot. Auto-fires at the nearest enemy in
/// range, and can be dragged onto another same-tier turret to merge into
/// the next tier (classic merge-defense mechanic).
class TurretComponent extends PositionComponent
    with HasGameReference<TurretDefenseGame>, TapCallbacks, DragCallbacks {
  int tier;
  int row;
  int col;

  late TurretStats stats;
  double _cooldown = 0;
  double _firingTimeLeft = 0;
  late final double _shootAnimDuration;

  late SpriteAnimationComponent _sprite;
  late TextComponent _levelLabel;
  late TextComponent _levelLabelShadow;
  AppLanguage? _labelLanguage;
  Vector2? _preDragPosition;
  bool _isDragging = false;

  TurretComponent({
    required this.tier,
    required this.row,
    required this.col,
    required Vector2 position,
  }) : super(position: position, size: Vector2(60, 60), anchor: Anchor.center, priority: 5) {
    stats = TurretStats(tier);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Slightly generous hitbox so drags/taps register comfortably on touch.
    final r = size.x / 2 + 6;
    final c = size / 2;
    return (point - c).length <= r;
  }

  @override
  Future<void> onLoad() async {
    final frames = await GameAssets.loadFrames(stats.assetDir);
    const stepTime = 0.03;
    _shootAnimDuration = frames.length * stepTime;
    _sprite = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(frames, stepTime: stepTime, loop: false),
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      playing: false,
    );
    add(_sprite);

    _labelLanguage = game.economy.language;
    final labelText = Strings(_labelLanguage!).turretLevel(tier);
    const labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    _levelLabelShadow = TextComponent(
      text: labelText,
      textRenderer: TextPaint(style: labelStyle.copyWith(color: Colors.black)),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2 + 1, size.y - 5),
    );
    _levelLabel = TextComponent(
      text: labelText,
      textRenderer: TextPaint(style: labelStyle),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, size.y - 6),
    );
    add(_levelLabelShadow);
    add(_levelLabel);
  }

  void rebuildStats() {
    stats = TurretStats(tier);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.economy.language != _labelLanguage) {
      _labelLanguage = game.economy.language;
      final labelText = Strings(_labelLanguage!).turretLevel(tier);
      _levelLabel.text = labelText;
      _levelLabelShadow.text = labelText;
    }

    if (_firingTimeLeft > 0) {
      _firingTimeLeft -= dt;
      if (_firingTimeLeft <= 0) {
        _sprite.playing = false;
        _sprite.animationTicker?.reset();
      }
    }

    if (_isDragging || game.economy.gameOver) return;

    _cooldown -= dt;
    if (_cooldown <= 0) {
      final target = game.findNearestEnemyInRange(position, stats.range);
      if (target != null) {
        game.fireProjectileFromTurret(this, target, stats.damage);
        _cooldown = stats.fireInterval;
        _firingTimeLeft = _shootAnimDuration;
        _sprite.playing = true;
        _sprite.animationTicker?.reset();
      }
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (game.economy.sellMode) {
      game.sellTurret(this);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (game.economy.sellMode) return;
    _isDragging = true;
    _preDragPosition = position.clone();
    priority = 20;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragging) return;
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isDragging) return;
    _isDragging = false;
    priority = 5;
    game.handleTurretDrop(this, position.clone(), _preDragPosition!);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (!_isDragging) return;
    _isDragging = false;
    priority = 5;
    if (_preDragPosition != null) {
      position = _preDragPosition!;
    }
  }
}
