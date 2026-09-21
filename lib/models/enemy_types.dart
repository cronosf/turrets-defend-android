enum EnemyKind { ground, fly, hybrid }

class EnemyType {
  final String id;
  final EnemyKind kind;
  final String assetDir; // relative to assets/images/
  final int unlockWave;
  final double baseHp;
  final double baseSpeed;
  final double baseDamage;
  final int baseReward;

  const EnemyType({
    required this.id,
    required this.kind,
    required this.assetDir,
    required this.unlockWave,
    required this.baseHp,
    required this.baseSpeed,
    required this.baseDamage,
    required this.baseReward,
  });

  /// Progressive kill score: 10 pts for wave-1 basics, doubling with every
  /// unlock tier (10, 20, 40, 80 ...) so tougher, later enemies are worth
  /// dramatically more.
  int get scorePoints => 10 * (1 << (unlockWave - 1));
}

/// All 15 enemies from the asset kit (8 ground beetles, 3 flyers, 4 hybrids),
/// unlocked progressively as endless-mode waves climb so variety keeps
/// growing instead of the player seeing everything in wave 1.
const List<EnemyType> kEnemyTypes = [
  EnemyType(
    id: 'blackbeetle',
    kind: EnemyKind.ground,
    assetDir: 'enemies/ground/blackbeetle',
    unlockWave: 1,
    baseHp: 24,
    baseSpeed: 40,
    baseDamage: 8,
    baseReward: 3,
  ),
  EnemyType(
    id: 'redbeetle',
    kind: EnemyKind.ground,
    assetDir: 'enemies/ground/redbeetle',
    unlockWave: 1,
    baseHp: 24,
    baseSpeed: 44,
    baseDamage: 8,
    baseReward: 3,
  ),
  EnemyType(
    id: 'bluebeetle',
    kind: EnemyKind.ground,
    assetDir: 'enemies/ground/bluebeetle',
    unlockWave: 2,
    baseHp: 30,
    baseSpeed: 42,
    baseDamage: 9,
    baseReward: 4,
  ),
  EnemyType(
    id: 'greenbeetle',
    kind: EnemyKind.ground,
    assetDir: 'enemies/ground/greenbeetle',
    unlockWave: 2,
    baseHp: 30,
    baseSpeed: 42,
    baseDamage: 9,
    baseReward: 4,
  ),
  EnemyType(
    id: 'orangebeetle',
    kind: EnemyKind.ground,
    assetDir: 'enemies/ground/orangebeetle',
    unlockWave: 3,
    baseHp: 36,
    baseSpeed: 46,
    baseDamage: 10,
    baseReward: 4,
  ),
  EnemyType(
    id: 'purplebeetle',
    kind: EnemyKind.ground,
    assetDir: 'enemies/ground/purplebeetle',
    unlockWave: 3,
    baseHp: 36,
    baseSpeed: 46,
    baseDamage: 10,
    baseReward: 4,
  ),
  EnemyType(
    id: 'darkbeetle',
    kind: EnemyKind.ground,
    assetDir: 'enemies/ground/darkbeetle',
    unlockWave: 4,
    baseHp: 46,
    baseSpeed: 48,
    baseDamage: 12,
    baseReward: 5,
  ),
  EnemyType(
    id: 'hornbeetle',
    kind: EnemyKind.ground,
    assetDir: 'enemies/ground/hornbeetle',
    unlockWave: 4,
    baseHp: 46,
    baseSpeed: 48,
    baseDamage: 12,
    baseReward: 5,
  ),
  EnemyType(
    id: 'flyingblue',
    kind: EnemyKind.fly,
    assetDir: 'enemies/fly/flyingblue',
    unlockWave: 3,
    baseHp: 16,
    baseSpeed: 62,
    baseDamage: 6,
    baseReward: 4,
  ),
  EnemyType(
    id: 'flyingorange',
    kind: EnemyKind.fly,
    assetDir: 'enemies/fly/flyingorange',
    unlockWave: 5,
    baseHp: 20,
    baseSpeed: 66,
    baseDamage: 7,
    baseReward: 5,
  ),
  EnemyType(
    id: 'flyingbrown',
    kind: EnemyKind.fly,
    assetDir: 'enemies/fly/flyingbrown',
    unlockWave: 6,
    baseHp: 22,
    baseSpeed: 70,
    baseDamage: 7,
    baseReward: 5,
  ),
  EnemyType(
    id: 'hybridblue',
    kind: EnemyKind.hybrid,
    assetDir: 'enemies/hybrid/hybridblue',
    unlockWave: 6,
    baseHp: 60,
    baseSpeed: 46,
    baseDamage: 14,
    baseReward: 7,
  ),
  EnemyType(
    id: 'hybridgreen',
    kind: EnemyKind.hybrid,
    assetDir: 'enemies/hybrid/hybridgreen',
    unlockWave: 7,
    baseHp: 64,
    baseSpeed: 46,
    baseDamage: 14,
    baseReward: 7,
  ),
  EnemyType(
    id: 'hybridred',
    kind: EnemyKind.hybrid,
    assetDir: 'enemies/hybrid/hybridred',
    unlockWave: 8,
    baseHp: 68,
    baseSpeed: 48,
    baseDamage: 15,
    baseReward: 8,
  ),
  EnemyType(
    id: 'hybridpur',
    kind: EnemyKind.hybrid,
    assetDir: 'enemies/hybrid/hybridpur',
    unlockWave: 9,
    baseHp: 72,
    baseSpeed: 48,
    baseDamage: 15,
    baseReward: 8,
  ),
];
