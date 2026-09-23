/// A boss enemy's fixed identity: its art and how to slice it. Everything
/// that actually scales per-encounter (HP, damage) is computed separately
/// (see BossComponent/TurretDefenseGame) rather than stored here, since the
/// same boss type reappears repeatedly, each time tougher — see the design
/// note in TurretDefenseGame's boss-wave code.
class BossType {
  const BossType({
    required this.id,
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
/// rather than requiring a new art asset for every single encounter.
const List<BossType> kBossTypes = [
  BossType(
    id: 'golem2',
    // Walking/0_Golem_Walking_000.png.._023.png, cropped to a shared
    // bounding box (402x598 original -> aspectRatio 402/598) so the
    // 24-frame run cycle doesn't jitter in size frame to frame.
    walkFramesDirectory: 'bosses/golem2',
    artworkTopFraction: 0.01,
    aspectRatio: 402 / 598,
  ),
  BossType(
    id: 'goblin',
    walkFramesDirectory: 'bosses/goblin',
    artworkTopFraction: 0,
    aspectRatio: 405 / 542,
  ),
  BossType(
    id: 'ogre',
    walkFramesDirectory: 'bosses/ogre',
    artworkTopFraction: 0,
    aspectRatio: 403 / 566,
  ),
  BossType(
    id: 'orc',
    walkFramesDirectory: 'bosses/orc',
    artworkTopFraction: 0,
    aspectRatio: 406 / 609,
  ),
];
