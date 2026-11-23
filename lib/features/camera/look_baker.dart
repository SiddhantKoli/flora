import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

import 'camera_look.dart';

class LookBakeException implements Exception {
  const LookBakeException(this.message);
  final String message;
  @override
  String toString() => 'LookBakeException: $message';
}

/// Applies a [CameraLook] to a COPY of a photo. The original file is never
/// modified. Keeps the original aspect ratio; only downsizes if the long edge
/// exceeds [maxLongEdge].
class LookBaker {
  static const int maxLongEdge = 2560;

  /// Returns the path of the processed copy (next to the original).
  static Future<String> bake({
    required String originalPath,
    required String lookId,
  }) async {
    final look = lookById(lookId);
    if (look.isNatural) return originalPath;

    final dot = originalPath.lastIndexOf('.');
    final base = dot > 0 ? originalPath.substring(0, dot) : originalPath;
    final outPath = '${base}_$lookId.jpg';

    final ok = await compute(
      _bakeInIsolate,
      _BakeRequest(originalPath, outPath, lookId),
    );
    if (!ok) throw const LookBakeException('Could not decode the photo.');
    return outPath;
  }
}

class _BakeRequest {
  const _BakeRequest(this.inPath, this.outPath, this.lookId);
  final String inPath;
  final String outPath;
  final String lookId;
}

double _smoothstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

int _byte(double v) => v < 0 ? 0 : (v > 255 ? 255 : v.round());

bool _bakeInIsolate(_BakeRequest r) {
  final look = lookById(r.lookId);
  var image = img.decodeImage(File(r.inPath).readAsBytesSync());
  if (image == null) return false;

  image = img.bakeOrientation(image);
  if (image.hasPalette || image.numChannels < 3) {
    image = image.convert(numChannels: 3);
  }

  final longEdge = math.max(image.width, image.height);
  if (longEdge > LookBaker.maxLongEdge) {
    image = image.width >= image.height
        ? img.copyResize(image, width: LookBaker.maxLongEdge)
        : img.copyResize(image, height: LookBaker.maxLongEdge);
  }

  final m = look.matrix;
  final cx = (image.width - 1) / 2;
  final cy = (image.height - 1) / 2;
  final maxD = math.sqrt(cx * cx + cy * cy);
  final seed =
      r.inPath.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
  final rng = math.Random(seed);
  final needsDistance = look.glow > 0 || look.vignette > 0;

  for (final p in image) {
    final r0 = p.r.toDouble(), g0 = p.g.toDouble(), b0 = p.b.toDouble();
    var nr = m[0] * r0 + m[1] * g0 + m[2] * b0 + m[4];
    var ng = m[5] * r0 + m[6] * g0 + m[7] * b0 + m[9];
    var nb = m[10] * r0 + m[11] * g0 + m[12] * b0 + m[14];

    if (needsDistance) {
      final dx = p.x - cx, dy = p.y - cy;
      final d = math.sqrt(dx * dx + dy * dy) / maxD;
      if (look.glow > 0) {
        final add = look.glow * 64 * (1 - d.clamp(0.0, 1.0));
        nr += add;
        ng += add;
        nb += add;
      }
      if (look.vignette > 0) {
        final f = 1 - look.vignette * _smoothstep(0.55, 1.0, d);
        nr *= f;
        ng *= f;
        nb *= f;
      }
    }

    if (look.grain > 0) {
      // Luminance-only grain: same value on all channels, no colour noise.
      final n = (rng.nextDouble() - 0.5) * 2 * look.grain * 127;
      nr += n;
      ng += n;
      nb += n;
    }

    p
      ..r = _byte(nr)
      ..g = _byte(ng)
      ..b = _byte(nb);
  }

  File(r.outPath).writeAsBytesSync(img.encodeJpg(image, quality: 92));
  return true;
}
