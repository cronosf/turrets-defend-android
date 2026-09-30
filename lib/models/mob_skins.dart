import 'dart:math' as math;

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
    this.walkSheetPath = '',
    this.framesDirectory,
    this.sizeScale = 1,
    this.frameSize = 64,
    this.directionRow = 1,
    this.frameCount = 6,
    this.artworkTopFraction = 0,
  });

  /// Which enemies this skin replaces when equipped.
  final EnemyKind kind;

  /// Relative to assets/images/. Unused (empty) when [framesDirectory] is
  /// set instead.
  final String walkSheetPath;

  /// For skins shipped as one PNG per frame (e.g. the fairies) rather than
  /// a sheet: the folder under assets/images/ holding the looping frames
  /// (see GameAssets.loadFrames). Takes priority over [walkSheetPath].
  final String? framesDirectory;

  /// Multiplier on the shared mob_skin render size (TurretDefenseGame's
  /// _mobSkinSize) for art that needs to read smaller/larger.
  final double sizeScale;

  // Sheet layout (see GameAssets.loadSheetRow) — kits in this family are
  // packed as a grid of fixed-size frames (rows = facing direction), but
  // not every creature has the same walk-cycle length, so frameCount is
  // per-skin rather than a shared constant (predator_plant: 6, slime: 8).
  final double frameSize;
  final int directionRow;
  final int frameCount;

  /// Same idea as BossType.artworkTopFraction: fraction (0-1) of empty
  /// transparent space above the actual artwork, so EnemyComponent can
  /// anchor the HP bar to where the art actually starts instead of the
  /// raw frame top. 0 (the default, and every existing sheet-based skin
  /// here) means the art already reaches the frame's top edge.
  final double artworkTopFraction;
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
  // Flying skins (EnemyKind.fly): frames are pre-cropped square with the
  // art flush against the top edge, so no artworkTopFraction is needed and
  // the HP bar sits right on the fairy. Size matches the War Orc's
  // (see TurretDefenseGame._orcSkinSizeScale), then -10% like the orcs.
  'mob_fairy1': MobSkinType(kind: EnemyKind.fly, framesDirectory: 'mobs/fairy/1', sizeScale: kFairySkinSizeScale),
  'mob_fairy2': MobSkinType(kind: EnemyKind.fly, framesDirectory: 'mobs/fairy/2', sizeScale: kFairySkinSizeScale),
  'mob_fairy3': MobSkinType(kind: EnemyKind.fly, framesDirectory: 'mobs/fairy/3', sizeScale: kFairySkinSizeScale),
};

/// War Orc render scale (vs. the shared mob_skin size) — shrunk by 15% and
/// then another 10%. Fairies use the same value so both read equal in size.
const double kOrcSkinSizeScale = 0.85 * 0.9;
const double kFairySkinSizeScale = kOrcSkinSizeScale;

/// The "War Orc" skin (bought once in the shop as a bundle — see
/// migration_add_orcs2_mob_skin.sql — but equipped independently per
/// EnemyKind like any other mob_skin) isn't a single fixed [MobSkinType]
/// like the ones in [kMobSkinTypes]: which of its 3 orc designs actually
/// shows is rolled per spawn instead of fixed at equip time, and differs
/// by kind — ground always gets the same (mildest) design, hybrid rolls
/// between the two tougher ones. See [resolveOrc2GroundVariantIndex] /
/// [resolveOrc2HybridVariantIndex] and EnemyComponent.onLoad, where this
/// branches off from the normal kMobSkinTypes lookup.
const String kOrc2AssetKey = 'mob_orc2';

/// assets/images/ prefix for each of the 3 orc_2 designs' walk-cycle frame
/// directories (one PNG per frame, loaded via GameAssets.loadFrames — same
/// convention as boss art, unlike the sheet-based skins above). Index order
/// matches the source kit's "1_ORK"/"2_ORK"/"3_ORK".
const List<String> kOrc2VariantDirs = [
  'mobs/orcs_2/1',
  'mobs/orcs_2/2',
  'mobs/orcs_2/3',
];

/// Fraction of empty space above the art in each orc_2 variant's frame —
/// see MobSkinType.artworkTopFraction's doc comment. Each variant's source
/// frames are landscape (~1.3:1) once tightly cropped, but every other
/// part of this render pipeline (EnemyComponent's fixed square render box,
/// every other mob_skin's literally-square sheet frames) assumes a square
/// source, so these were padded top/bottom into a square canvas instead of
/// left uncropped-and-stretched (which visibly squished the character) or
/// cropped tighter on width (which would have clipped the raised weapon
/// arm on some frames). That padding is exactly the "blank space" that
/// would otherwise separate the HP bar from the character — this fraction
/// is what keeps the bar anchored to the actual art instead of the padded
/// box top. Measured directly off the padded frames.
const List<double> kOrc2VariantTopFractions = [0.1232, 0.1101, 0.1128];

/// Ground mobs equipped with this skin always use the mildest design —
/// 1_ORK (index 0) — no randomness on that side, unlike hybrid below.
int resolveOrc2GroundVariantIndex() => 0;

/// Hybrid mobs equipped with this skin pick between the two tougher-
/// looking designs, 2_ORK and 3_ORK (indices 1-2): random between the two
/// through wave 30 (so both show up while a run is still building up),
/// then always the toughest-looking one (3_ORK, armored with a battle-axe)
/// from wave 31 on, matching how much tankier mobs already are that deep
/// into an endless run.
int resolveOrc2HybridVariantIndex(int wave, math.Random rng) {
  if (wave > 30) return kOrc2VariantDirs.length - 1;
  return 1 + rng.nextInt(kOrc2VariantDirs.length - 1);
}
