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
    this.attackFramesDirectory,
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
  /// 'golem'/'goblin'/'ogre'/'orc'/'wraith_emerald'/'wraith_wanderer'/
  /// 'wraith_shadow'. [kBossTypes] itself always lists each
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

  /// Optional one-shot "weapon swing" animation (same
  /// directory-of-frames convention as [walkFramesDirectory]) that
  /// BossComponent periodically plays in place of the walk loop while the
  /// boss is on screen and approaching — purely a visual flourish, not
  /// tied to any actual attack/damage (bosses don't deal damage until
  /// they reach the base). Only set for skins whose source kit actually
  /// ships an attack animation (currently the 3 goblin-family and 3 human
  /// reward boss_skin variants — see kBossSkinVariants).
  ///
  /// BossComponent always renders both animations into the exact same
  /// fixed size (derived from [aspectRatio], i.e. the *walk* crop's own
  /// proportions) — when processing these frames, crop tight to the
  /// attack pose's own bounding box and leave it at that pose's natural
  /// (usually wider, because of the outstretched weapon) aspect ratio.
  /// Padding it to match the walk crop's aspect instead looks tidier on
  /// paper but actually shrinks the character once Flame stretches that
  /// now-padded canvas into the same box — a real bug that shipped once
  /// already. A little squish/stretch from the aspect mismatch is far
  /// less noticeable than the boss visibly shrinking every ~2 seconds.
  final String? attackFramesDirectory;

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
  // Three new slots past orc — tougher than every basic above by the same
  // repeat-of-the-rotation scaling every earlier slot already uses (see
  // TurretDefenseGame's boss-wave code), no separate difficulty knob needed
  // here. Ghostly "wraith" kit, each its own colorway (206x281/218x284/
  // 222x291 -> aspect ratios below).
  BossType(
    id: 'wraith_emerald',
    slotId: 'wraith_emerald',
    walkFramesDirectory: 'bosses/wraith_emerald',
    artworkTopFraction: 0.0071,
    aspectRatio: 206 / 281,
  ),
  BossType(
    id: 'wraith_wanderer',
    slotId: 'wraith_wanderer',
    walkFramesDirectory: 'bosses/wraith_wanderer',
    artworkTopFraction: 0.007,
    aspectRatio: 218 / 284,
  ),
  BossType(
    id: 'wraith_shadow',
    slotId: 'wraith_shadow',
    walkFramesDirectory: 'bosses/wraith_shadow',
    artworkTopFraction: 0.0069,
    aspectRatio: 222 / 291,
  ),
];

/// Purchasable (or, for the 3 "boss_caveman"/"boss_giant_goblin"/
/// "boss_viking" entries, reward-claimable — see the achievements screen's
/// rewards section) alternate skins for a boss slot, keyed by shop_items.
/// metadata's asset_key exactly (e.g. "boss_golem1") — this is also what
/// names the shop preview icon (assets/images/shop/$asset_key.png), so the
/// two have to match. NOT part of [kBossTypes]' own rotation (that list
/// always cycles through each slot's basic look).
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
  // Reward-only skins for the 'golem' slot — never sold in the shop
  // (shop_items.is_active = 0 for these 3), only granted once by claiming
  // one from the achievements screen's rewards section after filling the
  // whole 40-figure album. See AchievementsScreen.
  'boss_caveman': BossType(
    id: 'caveman',
    slotId: 'golem',
    walkFramesDirectory: 'bosses/human_caveman',
    attackFramesDirectory: 'bosses/human_caveman_attack',
    artworkTopFraction: 0,
    aspectRatio: 267 / 443,
  ),
  'boss_giant_goblin': BossType(
    id: 'giant_goblin',
    slotId: 'golem',
    walkFramesDirectory: 'bosses/human_giant_goblin',
    attackFramesDirectory: 'bosses/human_giant_goblin_attack',
    artworkTopFraction: 0,
    aspectRatio: 286 / 441,
  ),
  'boss_viking': BossType(
    id: 'viking',
    slotId: 'golem',
    walkFramesDirectory: 'bosses/human_viking',
    attackFramesDirectory: 'bosses/human_viking_attack',
    artworkTopFraction: 0.0023,
    aspectRatio: 278 / 435,
  ),
  // Purchasable skins for the goblin/ogre/orc slots (previously basic-only)
  // — a single "goblin" character kit reused across all three slots per
  // the asset pack's own directory order (Chief/Female/Male -> goblin/
  // ogre/orc), same pattern as the golem1/golem3 alternates above.
  'boss_goblin_chief': BossType(
    id: 'goblin_chief',
    slotId: 'goblin',
    walkFramesDirectory: 'bosses/goblin_skin_chief',
    attackFramesDirectory: 'bosses/goblin_skin_chief_attack',
    artworkTopFraction: 0,
    aspectRatio: 249 / 312,
  ),
  'boss_ogre_shaman': BossType(
    id: 'ogre_shaman',
    slotId: 'ogre',
    walkFramesDirectory: 'bosses/goblin_skin_female',
    attackFramesDirectory: 'bosses/goblin_skin_female_attack',
    artworkTopFraction: 0,
    aspectRatio: 233 / 326,
  ),
  'boss_orc_warrior': BossType(
    id: 'orc_warrior',
    slotId: 'orc',
    walkFramesDirectory: 'bosses/goblin_skin_male',
    attackFramesDirectory: 'bosses/goblin_skin_male_attack',
    artworkTopFraction: 0,
    aspectRatio: 253 / 289,
  ),
};

/// The 3 reward-only skins claimable from the achievements screen's rewards
/// section — a player can claim exactly one, ever, once their achievements
/// album is full. Keyed by `shop_items.sku` (what `POST
/// /rewards/claim-boss-skin` takes and what an owned item's `sku` field
/// reads back as) with the matching [kBossSkinVariants] asset_key as the
/// value. Order here is the display order in that section.
const Map<String, String> kBossRewardSkus = {
  'boss_skin_caveman': 'boss_caveman',
  'boss_skin_giant_goblin': 'boss_giant_goblin',
  'boss_skin_viking': 'boss_viking',
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
