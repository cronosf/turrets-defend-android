import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../game_assets.dart';
import '../../models/enemy_types.dart';
import '../../models/mob_skins.dart';
import '../turret_defense_game.dart';
import 'targetable.dart';

/// A single enemy walking/flying down the battlefield toward the base.
class EnemyComponent extends PositionComponent
    with HasGameReference<TurretDefenseGame>, Targetable {
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
    Vector2? size,
  })  : hp = maxHp,
        _swayPhase = math.Random().nextDouble() * math.pi * 2,
        super(position: position, size: size ?? Vector2(48, 48), anchor: Anchor.center);

  @override
  bool get isDead => _dead;

  static final _rng = math.Random();

  @override
  Future<void> onLoad() async {
    // A purchased mob_skin fully replaces this enemy kind's art (unlike
    // turret/bullet skins, which just tint the base sprite) — see
    // models/mob_skins.dart. Each EnemyKind is its own equip slot, so a
    // ground skin and a hybrid skin can be equipped at the same time.
    final skinKey = game.economy.equippedMobSkinByKind[type.kind.name];
    List<Sprite> frames;
    double artworkTopFraction = 0;
    if (skinKey == kOrc2AssetKey) {
      // See kOrc2AssetKey's doc comment — its 3 designs are rolled per
      // spawn rather than being one fixed MobSkinType, and which ones are
      // even in play depends on which kind this enemy is (ground always
      // gets the mildest design; hybrid rolls between the two tougher
      // ones).
      final variantIndex = type.kind == EnemyKind.ground
          ? resolveOrc2GroundVariantIndex()
          : resolveOrc2HybridVariantIndex(game.economy.wave, _rng);
      frames = await GameAssets.loadFrames(kOrc2VariantDirs[variantIndex]);
      artworkTopFraction = kOrc2VariantTopFractions[variantIndex];
    } else {
      final skin = skinKey != null ? kMobSkinTypes[skinKey] : null;
      frames = skin != null
          ? await GameAssets.loadSheetRow(
              skin.walkSheetPath,
              frameWidth: skin.frameSize,
              frameHeight: skin.frameSize,
              row: skin.directionRow,
              columns: skin.frameCount,
            )
          : await GameAssets.loadFrames(type.assetDir);
      artworkTopFraction = skin?.artworkTopFraction ?? 0;
    }
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

    // 70% of the sprite's width (centered) rather than the full width —
    // full-width read as too thick/wide once mob_skin-equipped enemies
    // render bigger.
    final barWidth = size.x * 0.7;
    final barX = (size.x - barWidth) / 2;
    // Anchored to where the equipped skin's art actually starts (see
    // MobSkinType.artworkTopFraction) rather than the raw frame top —
    // same reasoning as BossComponent's own HP bar. 0 for the base/no-skin
    // case reproduces the previous fixed "-8" exactly.
    final barY = size.y * artworkTopFraction - 8;
    _hpBarBg = RectangleComponent(
      position: Vector2(barX, barY),
      size: Vector2(barWidth, 5),
      paint: Paint()..color = Colors.black54,
    );
    _hpBarFill = RectangleComponent(
      position: Vector2(barX, barY),
      size: Vector2(barWidth, 5),
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

  @override
  void takeDamage(double amount) {
    if (_dead) return;
    hp -= amount;
    _hpBarFill.size = Vector2(_hpBarBg.size.x * (hp / maxHp).clamp(0, 1), 5);
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
