/// A single collectible achievement "figure" (see assets/images/logros/).
/// id is 1-40 and doubles as the image filename ("$id.png").
class Achievement {
  const Achievement(this.id);

  final int id;

  String get imagePath => 'assets/images/logros/$id.png';
}

const int kAchievementCount = 40;
final List<Achievement> kAchievements =
    List.generate(kAchievementCount, (i) => Achievement(i + 1));

/// Rolls which achievement a boss kill awards.
///
/// The 40 figures are split into two 20-wide pools matching which pair of
/// bosses can drop them — kBossTypes[0..1] (golem2/goblin) award ids 1-20,
/// kBossTypes[2..3] (ogre/orc) award ids 21-40 — see TurretDefenseGame's
/// boss-wave design note for why bosses come in cycling pairs. Within each
/// pool, the last 5 ids are the rare ones: unreachable at all until
/// [encounterNumber] (which repeat of that boss cycle this is — the game
/// is endless, so bosses keep repeating and getting tougher) passes
/// [_rareUnlockEncounter], and even then only drop [_rareDropChance] of
/// the time — "the last 5 are the hardest to get, at the higher boss
/// levels" per the spec.
Achievement rollAchievementForBoss({
  required int bossIndex,
  required int encounterNumber,
  required double Function() nextRandom,
}) {
  const poolSize = 20;
  const rareCount = 5;
  const commonCount = poolSize - rareCount;
  const rareUnlockEncounter = 3;
  const rareDropChance = 0.15;

  final poolStartId = bossIndex <= 1 ? 1 : 21;

  final rareEligible = encounterNumber >= rareUnlockEncounter;
  final rollsRare = rareEligible && nextRandom() < rareDropChance;

  final offset = rollsRare
      ? commonCount + (nextRandom() * rareCount).floor()
      : (nextRandom() * commonCount).floor();

  return kAchievements[poolStartId - 1 + offset];
}
