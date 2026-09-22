import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Dominant hue (0-1 turns) of the turret art's own base color — measured
/// from the T1 sprite's saturated pixels (mean ≈ 28.6°/360 = 0.0795). Used
/// as the reference point so a *rotation* filter lands close to the same
/// look as an absolute hue replace would (see
/// server/database/seed.sql's shop_items.metadata.tint_hue, and the
/// static shop-preview art generated the same way in
/// assets/images/shop/).
const double kTurretBaseHueTurns = 0.0795;

/// Same idea as [kTurretBaseHueTurns] but measured from
/// assets/images/projectile/Projectile1.png, for tinting bullet_effect
/// skins onto the projectile sprite.
const double kProjectileBaseHueTurns = 0.0863;

/// A hue-rotation [ColorFilter] (same math as the CSS/SVG `hueRotate`
/// filter) — used to reskin turret/bullet sprites at *runtime* instead of
/// pre-baking every tier x color combination as static art, so a single
/// purchased skin (see Economy.equippedTurretHue) visibly applies to every
/// tier at once.
///
/// [targetHueTurns] is the desired hue (0-1, matching a shop item's
/// `tint_hue` metadata); [baseHueTurns] is the sprite's own dominant hue,
/// so the rotation delta lands the sprite's colors on the target hue
/// rather than shifting them by the raw target value.
ColorFilter hueRotateFilter(double targetHueTurns, {double baseHueTurns = kTurretBaseHueTurns}) {
  final deltaRadians = (targetHueTurns - baseHueTurns) * 2 * math.pi;
  final cosA = math.cos(deltaRadians);
  final sinA = math.sin(deltaRadians);

  // Standard SVG feColorMatrix type="hueRotate" matrix (4x5, row-major,
  // last column is the additive offset — left at 0 for a pure rotation).
  final matrix = <double>[
    0.213 + cosA * 0.787 - sinA * 0.213,
    0.715 - cosA * 0.715 - sinA * 0.715,
    0.072 - cosA * 0.072 + sinA * 0.928,
    0,
    0,
    0.213 - cosA * 0.213 + sinA * 0.143,
    0.715 + cosA * 0.285 + sinA * 0.140,
    0.072 - cosA * 0.072 - sinA * 0.283,
    0,
    0,
    0.213 - cosA * 0.213 - sinA * 0.787,
    0.715 - cosA * 0.715 + sinA * 0.715,
    0.072 + cosA * 0.928 + sinA * 0.072,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
  return ColorFilter.matrix(matrix);
}
