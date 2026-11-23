import 'package:flutter_test/flutter_test.dart';

// TODO: change `flora` to your app's package name.
import 'package:flora/features/camera/camera_look.dart';

void main() {
  test('Natural look is an identity matrix with no overlays', () {
    const identity = <double>[
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];
    final m = natural.matrix;
    expect(m.length, 20);
    for (var i = 0; i < 20; i++) {
      expect(m[i], closeTo(identity[i], 1e-9));
    }
    expect(natural.vignette, 0);
    expect(natural.glow, 0);
    expect(natural.grain, 0);
  });

  test('Natural is first and ids are unique', () {
    expect(kCameraLooks.first.isNatural, isTrue);
    final ids = kCameraLooks.map((l) => l.id).toSet();
    expect(ids.length, kCameraLooks.length);
  });

  test('Every look keeps alpha untouched and stays near-neutral', () {
    for (final look in kCameraLooks) {
      final m = look.matrix;
      expect(m.sublist(15), [0, 0, 0, 1, 0]);
      // Mid-grey should not shift far from mid-grey (no heavy colour casts).
      final r = m[0] * 128 + m[1] * 128 + m[2] * 128 + m[4];
      final b = m[10] * 128 + m[11] * 128 + m[12] * 128 + m[14];
      expect((r - b).abs(), lessThan(20), reason: look.name);
    }
  });

  test('lookById falls back to Natural', () {
    expect(lookById('does_not_exist').isNatural, isTrue);
  });
}
