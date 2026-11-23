const firstDiscoveryXp = 100;
const repeatObservationXp = 10;
const dailyQuestXp = 50;
const weeklyQuestXp = 200;

int levelForXp(int xp) => (xp ~/ 250) + 1;
int xpIntoLevel(int xp) => xp % 250;

/// A repeat of a species can earn XP once per local calendar day. An exact
/// image duplicate is rejected separately by the database before this runs.
int discoveryReward({required bool firstDiscovery, required bool rewardedRepeatToday}) {
  if (firstDiscovery) return firstDiscoveryXp;
  return rewardedRepeatToday ? 0 : repeatObservationXp;
}
