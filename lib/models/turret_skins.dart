/// A purchasable `turret_skin` that fully replaces every turret's art with a
/// warrior (seen from behind on the board, from the front in the Buy
/// sheet) and its shots with an animated attack effect — unlike the legacy
/// hue-rotate skins (see theme/hue_rotate.dart), which only tinted the base
/// turret. Keyed by the shop item's `asset_key` exactly (this is also what
/// names the shop icon, assets/images/shop/$asset_key.png).
class TurretSkinType {
  const TurretSkinType({
    required this.idleDir,
    required this.attackDir,
    required this.frontAsset,
    required this.effectDir,
    required this.effectSize,
  });

  /// Looping idle frames (back view), relative to assets/images/.
  final String idleDir;

  /// One-shot swing frames (back view), played every time the turret fires.
  final String attackDir;

  /// Front-view sprite shown in the Buy sheet, relative to assets/images/.
  final String frontAsset;

  /// Animated shot effect frames (drawn pointing right, rotated toward the
  /// target while it flies).
  final String effectDir;

  /// On-screen size of the shot effect (width x height in game pixels) —
  /// matches the frames' own aspect so nothing gets stretched.
  final (double, double) effectSize;
}

const Map<String, TurretSkinType> kTurretSkins = {
  'turret_warrior_black': TurretSkinType(
    idleDir: 'turrets/warrior_black_idle',
    attackDir: 'turrets/warrior_black_attack',
    frontAsset: 'turrets/warrior_front/warrior_black.png',
    effectDir: 'fx/fx_water_black',
    effectSize: (36, 18),
  ),
  'turret_warrior_blue': TurretSkinType(
    idleDir: 'turrets/warrior_blue_idle',
    attackDir: 'turrets/warrior_blue_attack',
    frontAsset: 'turrets/warrior_front/warrior_blue.png',
    effectDir: 'fx/fx_water_blue',
    effectSize: (36, 18),
  ),
  'turret_warrior_red': TurretSkinType(
    idleDir: 'turrets/warrior_red_idle',
    attackDir: 'turrets/warrior_red_attack',
    frontAsset: 'turrets/warrior_front/warrior_red.png',
    effectDir: 'fx/fx_flame_fuchsia',
    effectSize: (46, 21),
  ),
};
