import 'package:flutter_test/flutter_test.dart';
import 'package:flora/data/game_rules.dart';

void main() {
  test('first and repeat rewards are capped', () {
    expect(discoveryReward(firstDiscovery: true, rewardedRepeatToday: false), 100);
    expect(discoveryReward(firstDiscovery: false, rewardedRepeatToday: false), 10);
    expect(discoveryReward(firstDiscovery: false, rewardedRepeatToday: true), 0);
  });

  test('level boundaries are stable', () {
    expect(levelForXp(0), 1);
    expect(levelForXp(249), 1);
    expect(levelForXp(250), 2);
    expect(xpIntoLevel(250), 0);
  });
}
