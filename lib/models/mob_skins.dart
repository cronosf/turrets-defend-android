/// Ground-mob reskins purchasable in the shop (category `mob_skin`).
/// Unlike turret/bullet skins (a runtime hue-rotate tint on the base art —
/// see theme/hue_rotate.dart), these swap in completely different art: one
/// equipped skin replaces every ground-kind enemy's sprite for the whole
/// run, keyed by the shop item's `asset_key` (see EnemyComponent.onLoad).
/// All three currently share the same sheet layout (see
/// GameAssets.loadSheetRow): 64x64 frames, row 1 = front-facing, 6 columns.
class MobSkinType {
  const MobSkinType({required this.walkSheetPath});

  /// Relative to assets/images/.
  final String walkSheetPath;
}

const double kMobSkinFrameSize = 64;
const int kMobSkinDirectionRow = 1;
const int kMobSkinFrameCount = 6;

const Map<String, MobSkinType> kMobSkinTypes = {
  'plant1': MobSkinType(walkSheetPath: 'mobs/predator_plant/Plant1_Walk.png'),
  'plant2': MobSkinType(walkSheetPath: 'mobs/predator_plant/Plant2_Walk.png'),
  'plant3': MobSkinType(walkSheetPath: 'mobs/predator_plant/Plant3_Walk.png'),
};
