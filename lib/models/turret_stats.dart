import 'dart:math' as math;

/// Stat curve for a turret at a given merge tier (1..maxTier).
/// Every tier shares the same 15-frame shoot animation, just re-skinned art.
class TurretStats {
  static const int maxTier = 20;

  final int tier;
  late final double damage;
  late final double range;
  late final double fireInterval;
  late final int sellValue;

  TurretStats(this.tier) {
    final growth = math.pow(1.22, tier - 1).toDouble();
    damage = 8 * growth;
    // Reference gameplay shows turrets threatening nearly the whole lane, not
    // just the area right above the grid, so tier 1 alone should comfortably
    // clear half the battlefield's height.
    range = 480 + tier * 20;
    fireInterval = (0.95 - tier * 0.035).clamp(0.16, 0.95);
    sellValue = (6 * growth).round();
  }

  String get assetDir => 'turrets/t$tier';
}

/// Cost to buy a fresh tier-1 turret, scaling with how many have been bought
/// this run so the economy stays meaningful in endless mode.
int turretBuyCost(int purchasedCount) {
  return (20 * math.pow(1.16, purchasedCount)).round();
}
