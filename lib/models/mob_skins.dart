import 'enemy_types.dart';

/// A mob reskin purchasable in the shop (category `mob_skin`). Unlike
/// turret/bullet skins (a runtime hue-rotate tint on the base art — see
/// theme/hue_rotate.dart), these swap in completely different art: one
/// equipped skin replaces every enemy sprite of its [kind] for the whole
/// run, keyed by the shop item's `asset_key` (see EnemyComponent.onLoad).
/// Each [EnemyKind] is an independent equip slot — see
/// Economy.equippedMobSkinByKind — so a ground skin and a hybrid skin can
/// be equipped at the same time.
class MobSkinType {
  const MobSkinType({
    required this.kind,
    required this.walkSheetPath,
    this.frameSize = 64,
    this.directionRow = 1,
    this.frameCount = 6,
  });

  /// Which enemies this skin replaces when equipped.
  final EnemyKind kind;

  /// Relative to assets/images/.
  final String walkSheetPath;

  // Sheet layout (see GameAssets.loadSheetRow) — kits in this family are
  // packed as a grid of fixed-size frames (rows = facing direction), but
  // not every creature has the same walk-cycle length, so frameCount is
  // per-skin rather than a shared constant (predator_plant: 6, slime: 8).
  final double frameSize;
  final int directionRow;
  final int frameCount;
}

// Keyed by shop_items.metadata's asset_key exactly (e.g. "mob_plant1", not
// "plant1") — this is also what names the shop preview icon
// (assets/images/shop/$asset_key.png), so the two have to match.
const Map<String, MobSkinType> kMobSkinTypes = {
  'mob_plant1': MobSkinType(kind: EnemyKind.ground, walkSheetPath: 'mobs/predator_plant/Plant1_Walk.png'),
  'mob_plant2': MobSkinType(kind: EnemyKind.ground, walkSheetPath: 'mobs/predator_plant/Plant2_Walk.png'),
  'mob_plant3': MobSkinType(kind: EnemyKind.ground, walkSheetPath: 'mobs/predator_plant/Plant3_Walk.png'),
  'mob_slime1': MobSkinType(
    kind: EnemyKind.hybrid,
    walkSheetPath: 'mobs/slime/Slime1_Walk.png',
    frameCount: 8,
  ),
  'mob_slime2': MobSkinType(
    kind: EnemyKind.hybrid,
    walkSheetPath: 'mobs/slime/Slime2_Walk.png',
    frameCount: 8,
  ),
  'mob_slime3': MobSkinType(
    kind: EnemyKind.hybrid,
    walkSheetPath: 'mobs/slime/Slime3_Walk.png',
    frameCount: 8,
  ),
};
