import 'package:flutter_test/flutter_test.dart';
import 'package:flora/data/app_preferences.dart';

void main() {
  test('profile and accessibility preferences round trip', () {
    const original = AppPreferences(
        displayName: 'Sky',
        avatar: 'flower',
        largeText: true,
        reducedMotion: true,
        haptics: false,
        cameraSound: true);
    final restored = AppPreferences.fromJson(original.toJson());
    expect(restored.displayName, 'Sky');
    expect(restored.avatar, 'flower');
    expect(restored.largeText, isTrue);
    expect(restored.reducedMotion, isTrue);
    expect(restored.haptics, isFalse);
    expect(restored.cameraSound, isTrue);
  });

  test('missing settings use safe defaults', () {
    final restored = AppPreferences.fromJson({});
    expect(restored.displayName, '');
    expect(restored.avatar, 'leaf');
    expect(restored.largeText, isFalse);
    expect(restored.reducedMotion, isFalse);
    expect(restored.haptics, isTrue);
    expect(restored.cameraSound, isFalse);
  });
}
