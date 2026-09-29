import 'dart:ui' show Color, ColorFilter, BlendMode;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Paint;

/// One-shot visual effect (explosion or muzzle flash) that removes itself
/// once its frame sequence finishes playing.
class FxComponent extends SpriteAnimationComponent {
  FxComponent({
    required List<Sprite> frames,
    required Vector2 position,
    required Vector2 size,
    double stepTime = 0.02,
    Color? tint,
  }) : super(
          animation: SpriteAnimation.spriteList(frames, stepTime: stepTime, loop: false),
          position: position,
          size: size,
          anchor: Anchor.center,
          removeOnFinish: true,
        ) {
    // explosion1/2's frames are plain pale cream/tan puff shapes (no
    // internal shading) — srcATop recolors every opaque pixel to [tint]
    // solid, which is exactly a flat flame-orange/red burst for a shape
    // this simple. Cheap (one colorFilter, no new art) way to get a
    // fiery look out of the same frames every other explosion here reuses.
    if (tint != null) {
      paint = Paint()..colorFilter = ColorFilter.mode(tint, BlendMode.srcATop);
    }
  }
}
