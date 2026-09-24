/// A boss enemy's fixed identity: its art and how to slice it. Everything
/// that actually scales per-encounter (HP, damage) is computed separately
/// (see BossComponent/TurretDefenseGame) rather than stored here, since the
/// same boss type reappears repeatedly, each time tougher — see the design
/// note in TurretDefenseGame's boss-wave code.
class BossType {
  const BossType({
    required this.id,
    required this.slotId,
    this.walkSheetPath,
    this.frameSize,
    this.directionRow,
    this.frameCount,
    this.walkFramesDirectory,
    this.artworkTopFraction = 0,
    this.aspectRatio = 1,
  }) : assert(
          (walkFramesDirectory != null) !=
              (walkSheetPath != null && frameSize != null && directionRow != null && frameCount != null),
          'Provide exactly one of walkFramesDirectory or the sheet fields '
          '(walkSheetPath+frameSize+directionRow+frameCount), not both/neither.',
        );

  final String id;

  /// Which rotation slot ([kBossTypes] entry) this art belongs to —
  /// 'golem'/'goblin'/'ogre'/'orc'. [kBossTypes] itself always lists each
  /// slot's *basic* (default, non-purchasable) look; a purchasable
  /// alternate skin (see [kBossSkinVariants]) shares its slotId with the
  /// basic entry it can replace, and [resolveBossType] is what actually
  /// swaps one in at spawn time based on the player's equipped choice.
  /// Achievement rolls always key off the *slot*'s rotation index, never
  /// the equipped skin, so which figure you can earn doesn't change
  /// depending on which skin you have equipped.
  final String slotId;

  // --- Sheet-based art (see GameAssets.loadSheetRow) — used when a kit
  // ships one PNG per animation with several fixed-size frames arranged in
  // a grid (rows = facing direction) rather than individual frame files.
  final String? walkSheetPath;
  final double? frameSize;
  final int? directionRow;
  final int? frameCount;

  /// Directory-of-individual-frame-files art (see GameAssets.loadFrames),
  /// relative to assets/images/ — used when a kit already ships one PNG
  /// per frame (e.g. "0_Golem_Walking_000.png", "_001.png", ...).
  final String? walkFramesDirectory;

  /// Fraction (0-1) of empty transparent space above the actual artwork
  /// within each frame — art kits commonly leave padding so a taller pose
  /// (e.g. an attack animation) still fits the same frame, or so an
  /// animation's limb movement never gets clipped. Anchoring UI like the
  /// HP bar to the raw frame top would then float it visibly far above
  /// the boss itself; BossComponent uses this to anchor to where the art
  /// actually starts instead. Measure per boss (crop a frame and find the
  /// first non-transparent row) rather than guessing.
  final double artworkTopFraction;

  /// Width/height of the actual artwork (after any cropping) — used so a
  /// boss whose art isn't square doesn't get stretched into one.
  final double aspectRatio;
}

/// TurretDefenseGame cycles through this list for successive boss waves
/// (wave 5 -> index 0, wave 10 -> index 1, ...), reusing earlier entries
/// with higher HP once the list is exhausted (wave 25 -> index 0 again)
/// rather than requiring a new art asset for every single encounter. Each
/// entry here is a slot's *basic* look — see [resolveBossType] for how an
/// equipped alternate skin swaps in instead.
const List<BossType> kBossTypes = [
  BossType(
    id: 'golem2',
    slotId: 'golem',
    // Walking/0_Golem_Walking_000.png.._023.png, cropped to a shared
    // bounding box (402x598 original -> aspectRatio 402/598) so the
    // 24-frame run cycle doesn't jitter in size frame to frame.
    walkFramesDirectory: 'bosses/golem2',
    artworkTopFraction: 0.01,
    aspectRatio: 402 / 598,
  ),
  BossType(
    id: 'goblin',
    slotId: 'goblin',
    walkFramesDirectory: 'bosses/goblin',
    artworkTopFraction: 0,
    aspectRatio: 405 / 542,
  ),
  BossType(
    id: 'ogre',
    slotId: 'ogre',
    walkFramesDirectory: 'bosses/ogre',
    artworkTopFraction: 0,
    aspectRatio: 403 / 566,
  ),
  BossType(
    id: 'orc',
    slotId: 'orc',
    walkFramesDirectory: 'bosses/orc',
    artworkTopFraction: 0,
    aspectRatio: 406 / 609,
  ),
];

/// Purchasable alternate skins for a boss slot, keyed by shop_items.
/// metadata's asset_key exactly (e.g. "boss_golem1") — this is also what
/// names the shop preview icon (assets/images/shop/$asset_key.png), so the
/// two have to match. NOT part of [kBossTypes]' own rotation (that list
/// always cycles through each slot's basic look). Only the 'golem' slot
/// has alternates for now (goblin/ogre/orc: basic only).
const Map<String, BossType> kBossSkinVariants = {
  'boss_golem1': BossType(
    id: 'golem1',
    slotId: 'golem',
    // Crystal/ice-themed Golem_1 kit, same union-bbox-crop treatment as
    // the other boss walk cycles (412x554 -> aspectRatio 412/554).
    walkFramesDirectory: 'bosses/golem1',
    artworkTopFraction: 0.02,
    aspectRatio: 412 / 554,
  ),
  'boss_golem3': BossType(
    id: 'golem3',
    slotId: 'golem',
    // Lava/obsidian-themed Golem_3 kit (388x539 -> aspectRatio 388/539).
    walkFramesDirectory: 'bosses/golem3',
    artworkTopFraction: 0.01,
    aspectRatio: 388 / 539,
  ),
};

/// Resolves which [BossType] to actually spawn for a rotation slot: the
/// slot's basic look, unless [equippedVariantId] names one of its
/// [kBossSkinVariants] (falls back to basic for an unknown/stale id, e.g.
/// a variant that no longer exists).
BossType resolveBossType(BossType basic, String? equippedVariantId) {
  if (equippedVariantId == null) return basic;
  final variant = kBossSkinVariants[equippedVariantId];
  if (variant == null || variant.slotId != basic.slotId) return basic;
  return variant;
}
