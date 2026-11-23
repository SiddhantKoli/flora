/// Creative "digicam-inspired" looks for FLORA's Add a plant camera.
///
/// These are subtle colour/tone treatments that run inside the app. They are
/// NOT Canon or Sony modes and do not reproduce either company's processing.
/// Plain Dart only (no Flutter imports) so it can run inside an isolate.
class CameraLook {
  const CameraLook({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.inspiredBy,
    required this.traits,
    this.saturation = 1.0,
    this.contrast = 1.0,
    this.brightness = 0.0,
    this.warmth = 0.0,
    this.fade = 0.0,
    this.vignette = 0.0,
    this.glow = 0.0,
    this.grain = 0.0,
  })  : assert(saturation >= 0.92 && saturation <= 1.08),
        assert(contrast >= 0.92 && contrast <= 1.08),
        assert(brightness >= -6 && brightness <= 6),
        assert(warmth >= -0.04 && warmth <= 0.04),
        assert(fade >= 0 && fade <= 10),
        assert(vignette >= 0 && vignette <= 0.12),
        assert(glow >= 0 && glow <= 0.2),
        assert(grain >= 0 && grain <= 0.06);

  final String id;
  final String name;
  final String shortCode;
  final String inspiredBy;
  final String traits;

  /// 1.0 = unchanged. Guardrail: within 8% of natural.
  final double saturation;

  /// 1.0 = unchanged. Guardrail: within 8% of natural.
  final double contrast;

  /// Added to each channel (0-255 scale).
  final double brightness;

  /// Positive = warmer (more red, less blue). No hue rotation is ever applied.
  final double warmth;

  /// Lifts the black point (0-255 scale) for a slightly faded feel.
  final double fade;

  /// Corner darkening, 0-0.12.
  final double vignette;

  /// Soft centre-weighted brightening (flash-like), 0-0.2.
  final double glow;

  /// Fine luminance grain, 0-0.06. Applied to the saved photo only.
  final double grain;

  bool get isNatural => id == 'natural';
  bool get hasGrain => grain > 0;

  /// 5x4 colour matrix (Flutter ColorFilter.matrix layout, 0-255 offsets).
  /// The live preview and the saved photo use this same matrix.
  List<double> get matrix => buildMatrix(
        saturation: saturation,
        contrast: contrast,
        brightness: brightness,
        warmth: warmth,
        fade: fade,
      );

  static List<double> buildMatrix({
    double saturation = 1.0,
    double contrast = 1.0,
    double brightness = 0.0,
    double warmth = 0.0,
    double fade = 0.0,
  }) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final s = saturation;
    final sr = (1 - s) * lr, sg = (1 - s) * lg, sb = (1 - s) * lb;
    final sat = <List<double>>[
      [sr + s, sg, sb],
      [sr, sg + s, sb],
      [sr, sg, sb + s],
    ];
    final gains = <double>[1 + warmth, 1.0, 1 - warmth];
    final k = (255 - fade) / 255;
    final off = 128 * (1 - contrast) + brightness;
    final out = <double>[];
    for (var i = 0; i < 3; i++) {
      final scale = contrast * gains[i] * k;
      out.addAll([
        sat[i][0] * scale,
        sat[i][1] * scale,
        sat[i][2] * scale,
        0,
        off * k + fade,
      ]);
    }
    out.addAll([0, 0, 0, 1, 0]);
    return out;
  }
}

const natural = CameraLook(
  id: 'natural',
  name: 'Natural',
  shortCode: 'NAT',
  inspiredBy: 'No look applied',
  traits: 'Exactly what the camera captured.',
);

const daylightSnap = CameraLook(
  id: 'daylight_snap',
  name: 'Daylight Snap',
  shortCode: 'DSN',
  inspiredBy: 'Canon IXUS / PowerShot ELPH CCD compacts',
  traits: 'Gentle contrast, slightly warm, restrained colour.',
  saturation: 1.04,
  contrast: 1.06,
  brightness: 2,
  warmth: 0.03,
);

const zeissBright = CameraLook(
  id: 'zeiss_bright',
  name: 'Bright Compact',
  shortCode: 'BRT',
  inspiredBy: 'Sony Cyber-shot DSC-W series',
  traits: 'Clean, slightly cooler, a touch more colour pop.',
  saturation: 1.05,
  contrast: 1.04,
  brightness: 3,
  warmth: -0.03,
);

const flashSnapshot = CameraLook(
  id: 'flash_snapshot',
  name: 'Flash Snapshot',
  shortCode: 'FLS',
  inspiredBy: 'Canon IXUS built-in flash snapshots',
  traits: 'Soft centre glow and gentle edge falloff. Simulated lighting.',
  saturation: 1.02,
  contrast: 1.03,
  brightness: 4,
  vignette: 0.10,
  glow: 0.18,
);

const earlyCcd = CameraLook(
  id: 'early_ccd',
  name: 'Early CCD',
  shortCode: 'CCD',
  inspiredBy: 'Early Canon IXUS / ELPH 2-3 MP CCD models',
  traits: 'Faded blacks, light grain, small vignette. Detail stays sharp.',
  contrast: 0.96,
  warmth: 0.02,
  fade: 8,
  vignette: 0.08,
  grain: 0.05,
);

/// Natural is always first so it is one tap away.
const List<CameraLook> kCameraLooks = [
  natural,
  daylightSnap,
  zeissBright,
  flashSnapshot,
  earlyCcd,
];

CameraLook lookById(String id) =>
    kCameraLooks.firstWhere((l) => l.id == id, orElse: () => natural);

/// What the camera screen hands back to FLORA's review flow.
class CapturedPlantPhoto {
  const CapturedPlantPhoto({
    required this.originalPath,
    this.processedPath,
    this.lookId = 'natural',
  });

  /// The untouched capture (or gallery pick), original aspect ratio.
  final String originalPath;

  /// A copy with the look baked in, or null when no look was applied.
  final String? processedPath;
  final String lookId;

  bool get hasLook => processedPath != null;

  /// Show this in the review screen by default.
  String get displayPath => processedPath ?? originalPath;
}
