import 'package:flame/components.dart';

/// Anything a turret can lock onto and damage — regular enemies and bosses
/// alike. Turret-targeting and wave-clear code (TurretDefenseGame,
/// ProjectileComponent) only need this much; the different consequences of
/// a kill or of reaching the base stay specific to each concrete component
/// (see EnemyComponent._die/onEnemyKilled vs BossComponent._die/
/// onBossKilled).
mixin Targetable on PositionComponent {
  bool get isDead;
  void takeDamage(double amount);

  /// How close a homing projectile must get to [position] (its center) to
  /// count as a hit. Regular enemies are small enough that "the exact
  /// center" is a fine approximation of "touching it"; a boss can be most
  /// of the screen wide, so it overrides this to a fraction of its own
  /// size — otherwise a shot would visually sink deep into a boss's body
  /// before ever registering.
  double get hitRadius => 14;
}
