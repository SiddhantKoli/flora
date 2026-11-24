import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints the board, components and molded acrylic as vectors. The live camera
/// preview is a separate widget laid over the board by AtomicPurpleCameraSkin.
class AtomicPurpleHardwarePainter extends CustomPainter {
  const AtomicPurpleHardwarePainter();

  static const _pink = Color(0xFFF47BFF);
  static const _violet = Color(0xFFB94BE5);
  static const _pale = Color(0xFFFFD9FF);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 530);
    final outer = RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 3, 346, 522), const Radius.circular(43));
    final board = RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 16, 322, 496), const Radius.circular(34));

    canvas.drawRRect(
        outer,
        Paint()
          ..color = const Color(0xAA8F2ABC)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
    canvas.drawRRect(
        outer,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7F359A), Color(0xFF240C32), Color(0xFF48165D)],
          ).createShader(const Rect.fromLTWH(7, 3, 346, 522)));
    canvas.drawRRect(
        board,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, -.25),
            radius: 1.25,
            colors: [Color(0xFF220B2B), Color(0xFF0F0616)],
          ).createShader(const Rect.fromLTWH(19, 16, 322, 496)));

    canvas.save();
    canvas.clipRRect(board);
    _drawCircuitry(canvas);
    _drawComponents(canvas);
    _drawPixelFlowers(canvas);
    canvas.drawRRect(
        board,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x11512A61), Color(0x004F1764), Color(0x11672585)],
          ).createShader(const Rect.fromLTWH(19, 16, 322, 496)));
    canvas.restore();

    _drawAcrylic(canvas, outer);
    for (final point in const [
      Offset(40, 47),
      Offset(320, 47),
      Offset(40, 482),
      Offset(320, 482),
    ]) {
      _drawScrew(canvas, point);
    }
    canvas.restore();
  }

  void _drawCircuitry(Canvas canvas) {
    final rng = math.Random(41);
    final trace = Paint()
      ..color = const Color(0xCC9B5BAC)
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    final copper = Paint()
      ..color = const Color(0x99E49DCB)
      ..strokeWidth = .6;
    for (var i = 0; i < 102; i++) {
      final side = i.isEven;
      final x = side ? 24 + rng.nextDouble() * 77 : 259 + rng.nextDouble() * 75;
      final y = 20 + rng.nextDouble() * 485;
      final dx =
          side ? 13 + rng.nextDouble() * 35 : -13 - rng.nextDouble() * 35;
      final dy = (rng.nextDouble() - .5) * 29;
      final path = Path()
        ..moveTo(x, y)
        ..lineTo(x + dx * .45, y)
        ..lineTo(x + dx, y + dy)
        ..lineTo(x + dx * 1.2, y + dy);
      canvas.drawPath(path, trace);
      canvas.drawCircle(Offset(x + dx * 1.2, y + dy), 1, copper);
    }
    for (var i = 0; i < 42; i++) {
      final x = 56.0 + rng.nextDouble() * 245;
      final y = 315.0 + rng.nextDouble() * 176;
      final length = 8.0 + rng.nextDouble() * 38;
      final path = Path()
        ..moveTo(x, y)
        ..lineTo(x + length * .45, y)
        ..lineTo(x + length * .65, y + (i.isEven ? 5 : -5))
        ..lineTo(x + length, y + (i.isEven ? 5 : -5));
      canvas.drawPath(
          path,
          Paint()
            ..color =
                i.isEven ? const Color(0xAAE98BC1) : const Color(0xAA7A4C9D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .55);
      canvas.drawCircle(path.getBounds().bottomRight, .8,
          Paint()..color = const Color(0xAAA75D9E));
    }
    for (var i = 0; i < 70; i++) {
      final x = 34 + rng.nextDouble() * 292;
      final y =
          i.isEven ? 25 + rng.nextDouble() * 50 : 315 + rng.nextDouble() * 185;
      canvas.drawCircle(
          Offset(x, y),
          rng.nextDouble() * .8 + .35,
          Paint()
            ..color =
                i.isEven ? const Color(0xAAFFA5E5) : const Color(0x99854F9C));
    }
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 16; col++) {
        final x = 58.0 + col * 15.1;
        final y = 326.0 + row * 19.5;
        if ((row + col) % 4 == 0) {
          canvas.drawCircle(
              Offset(x, y), 1.15, Paint()..color = const Color(0x99D387B1));
        }
      }
    }
    final grain = math.Random(501);
    for (var i = 0; i < 560; i++) {
      final x = 23.0 + grain.nextDouble() * 314;
      final y = 21.0 + grain.nextDouble() * 484;
      final color =
          i.isEven ? const Color(0x336FE5B2) : const Color(0x665B346D);
      canvas.drawCircle(
          Offset(x, y), .25 + grain.nextDouble() * .4, Paint()..color = color);
    }
  }

  void _drawComponents(Canvas canvas) {
    _chip(canvas, const Rect.fromLTWH(72, 26, 91, 19), 16);
    _chip(canvas, const Rect.fromLTWH(182, 28, 56, 25), 10);
    _chip(canvas, const Rect.fromLTWH(51, 326, 66, 42), 12);
    _chip(canvas, const Rect.fromLTWH(70, 442, 65, 32), 12);
    _chip(canvas, const Rect.fromLTWH(259, 441, 56, 35), 10);
    _chip(canvas, const Rect.fromLTWH(271, 87, 47, 27), 8);
    _chip(canvas, const Rect.fromLTWH(35, 88, 28, 35), 6);
    _chip(canvas, const Rect.fromLTWH(294, 142, 31, 33), 6);
    _chip(canvas, const Rect.fromLTWH(82, 319, 54, 24), 10);
    _chip(canvas, const Rect.fromLTWH(225, 319, 45, 24), 8);
    _chip(canvas, const Rect.fromLTWH(37, 418, 30, 25), 6);
    _chip(canvas, const Rect.fromLTWH(241, 411, 43, 21), 8);
    final battery = RRect.fromRectAndRadius(
        const Rect.fromLTWH(244, 356, 52, 18), const Radius.circular(3));
    canvas.drawRRect(
        battery,
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFF351324),
            Color(0xFFF09B24),
            Color(0xFFAA5012),
          ]).createShader(const Rect.fromLTWH(244, 356, 52, 18)));
    canvas.drawLine(
        const Offset(250, 358),
        const Offset(286, 358),
        Paint()
          ..color = const Color(0xFFFFD177)
          ..strokeWidth = 1.4);
    for (var i = 0; i < 8; i++) {
      final y = 374.0 + i * 11.0;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(29, y, 10, 4), const Radius.circular(1)),
          Paint()..color = const Color(0x994D315B));
    }
    for (var i = 0; i < 21; i++) {
      final x = 39.0 + (i % 7) * 7.4;
      final y = 346.0 + (i ~/ 7) * 11;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, 4, 2), const Radius.circular(.5)),
          Paint()..color = const Color(0xFF9B6498));
    }
  }

  void _chip(Canvas canvas, Rect rect, int pins) {
    final shadow = rect.shift(const Offset(2, 3));
    canvas.drawRRect(RRect.fromRectAndRadius(shadow, const Radius.circular(3)),
        Paint()..color = const Color(0xAA080510));
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF321E3B), Color(0xFF100C19), Color(0xFF24142D)],
          ).createShader(rect));
    canvas.drawLine(
        rect.topLeft + const Offset(4, 3),
        rect.topRight + const Offset(-4, 3),
        Paint()
          ..color = const Color(0x884F3C58)
          ..strokeWidth = .8);
    for (var i = 0; i < pins; i++) {
      final x = rect.left + 4 + i * (rect.width - 8) / math.max(1, pins - 1);
      final metal = Paint()
        ..color = const Color(0xFFB17F9F)
        ..strokeWidth = 1.1;
      canvas.drawLine(Offset(x, rect.top - 3), Offset(x, rect.top), metal);
      canvas.drawLine(
          Offset(x, rect.bottom), Offset(x, rect.bottom + 3), metal);
    }
    canvas.drawCircle(
        rect.center, 1.1, Paint()..color = const Color(0x664C4450));
    if (rect.width >= 42) {
      final label = TextPainter(
        text: TextSpan(
            text: rect.width > 60 ? 'FLORA 01' : 'CAM IC',
            style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 4.5,
                letterSpacing: .5,
                color: Color(0x886E5A76))),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - 7);
      label.paint(canvas, rect.topLeft + const Offset(4, 7));
    }
  }

  void _drawPixelFlowers(Canvas canvas) {
    final leaf = Paint()..color = const Color(0xFFBDEB29);
    for (final square in const [
      Rect.fromLTWH(37, 133, 5, 5),
      Rect.fromLTWH(42, 128, 5, 5),
      Rect.fromLTWH(47, 123, 5, 5),
      Rect.fromLTWH(52, 122, 5, 5),
      Rect.fromLTWH(37, 139, 5, 5),
      Rect.fromLTWH(42, 144, 5, 5),
      Rect.fromLTWH(47, 150, 5, 5),
      Rect.fromLTWH(53, 143, 5, 5),
      Rect.fromLTWH(56, 136, 5, 5),
      Rect.fromLTWH(50, 155, 5, 5),
    ]) {
      canvas.drawRect(square, leaf);
    }
    canvas.drawLine(
        const Offset(50, 154),
        const Offset(51, 169),
        Paint()
          ..color = const Color(0xFF89BA26)
          ..strokeWidth = 2);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final center =
          Offset(61 + math.cos(angle) * 10, 375 + math.sin(angle) * 10);
      canvas.drawRect(
          Rect.fromCenter(center: center, width: 5, height: 5),
          Paint()
            ..color =
                i.isEven ? const Color(0xFFCF8CEF) : const Color(0xFFF4B9F9));
    }
    canvas.drawCircle(
        const Offset(61, 375), 3, Paint()..color = const Color(0xFFFFC66B));
  }

  void _drawAcrylic(Canvas canvas, RRect outer) {
    final glass = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x668A3AAF), Color(0x114F1764), Color(0x667D2B9A)],
        stops: [0, .47, 1],
      ).createShader(const Rect.fromLTWH(7, 3, 346, 522));
    canvas.drawRRect(outer, glass);
    _drawGlassRails(canvas);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..shader = const LinearGradient(
        colors: [_pale, _violet, _pink, Color(0xFF7F3BA9), _pale],
        stops: [0, .28, .54, .8, 1],
      ).createShader(const Rect.fromLTWH(7, 3, 346, 522));
    canvas.drawRRect(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..color = const Color(0xAAE844FA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    canvas.drawRRect(outer, rim);
    for (final inset in [10.0, 14.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  7 + inset, 3 + inset, 346 - inset * 2, 522 - inset * 2),
              Radius.circular(43 - inset * .4)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = inset == 10 ? 1.8 : .8
            ..color = inset == 10
                ? const Color(0x99FFE2FF)
                : const Color(0x77B659DC));
    }
    final highlight = Paint()
      ..color = const Color(0xE8FFD6FF)
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(62, 8), const Offset(286, 8), highlight);
    canvas.drawLine(const Offset(16, 90), const Offset(16, 240), highlight);
    canvas.drawLine(const Offset(31, 515), const Offset(149, 515), highlight);
    canvas.drawLine(const Offset(213, 515), const Offset(310, 515), highlight);
    canvas.drawLine(
        const Offset(345, 134),
        const Offset(345, 347),
        Paint()
          ..color = const Color(0xCCF595FF)
          ..strokeWidth = 1.5);
    for (final x in [53.0, 165.0, 291.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, 4, 25, 12), const Radius.circular(3)),
          Paint()..color = const Color(0x447F208E));
      canvas.drawLine(
          Offset(x + 3, 6),
          Offset(x + 22, 6),
          Paint()
            ..color = const Color(0xAAFFB9FF)
            ..strokeWidth = 1);
    }
    for (final x in [74.0, 166.0, 273.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, 512, 28, 10), const Radius.circular(3)),
          Paint()..color = const Color(0x667A267E));
    }
    for (final y in [126.0, 342.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(4, y, 10, 46), const Radius.circular(3)),
          Paint()..color = const Color(0x668E36A5));
      canvas.drawLine(
          Offset(6, y + 4),
          Offset(6, y + 42),
          Paint()
            ..color = const Color(0xAAFFBEFF)
            ..strokeWidth = 1.5);
    }
  }

  void _drawGlassRails(Canvas canvas) {
    for (final rect in const [
      Rect.fromLTWH(11, 102, 17, 314),
      Rect.fromLTWH(332, 102, 17, 314),
      Rect.fromLTWH(65, 10, 230, 17),
      Rect.fromLTWH(72, 500, 216, 17),
    ]) {
      final horizontal = rect.width > rect.height;
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          Paint()
            ..shader = LinearGradient(
              begin: horizontal ? Alignment.topCenter : Alignment.centerLeft,
              end: horizontal ? Alignment.bottomCenter : Alignment.centerRight,
              colors: const [
                Color(0x99FFE2FF),
                Color(0x449E39B6),
                Color(0x22FFFFFF),
                Color(0x8873218A)
              ],
            ).createShader(rect));
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)),
          Paint()
            ..color = const Color(0xBBF39AFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8);
    }
    for (final rect in const [
      Rect.fromLTWH(148, 1, 64, 25),
      Rect.fromLTWH(151, 503, 58, 26),
      Rect.fromLTWH(5, 180, 17, 62),
      Rect.fromLTWH(338, 283, 17, 58),
    ]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          Paint()
            ..shader = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x88F8C9FF),
                  Color(0x55522667),
                  Color(0xAAB34CCE)
                ]).createShader(rect));
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(3)),
          Paint()
            ..color = const Color(0xAAFFD2FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7);
    }
    for (final point in const [
      Offset(56, 6),
      Offset(260, 8),
      Offset(14, 275),
      Offset(345, 172),
      Offset(240, 518),
      Offset(316, 491),
    ]) {
      canvas.drawCircle(
          point,
          7,
          Paint()
            ..color = const Color(0xAAE65AFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(point, 1.2, Paint()..color = const Color(0xFFFFE8FF));
    }
  }

  void _drawScrew(Canvas canvas, Offset center) {
    final circle = Rect.fromCircle(center: center, radius: 12);
    canvas.drawCircle(
        center,
        13,
        Paint()
          ..color = const Color(0xAA7F2999)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(
        center,
        12,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.45),
            radius: .95,
            colors: [Color(0xFFFFF3E6), Color(0xFFBFA5A9), Color(0xFF45383D)],
          ).createShader(circle));
    canvas.drawCircle(
        center,
        9.2,
        Paint()
          ..color = const Color(0xFF60455F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.drawLine(
        center + const Offset(-4, 0),
        center + const Offset(4, 0),
        Paint()
          ..color = const Color(0xFF2C1A2D)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        center + const Offset(0, -4),
        center + const Offset(0, 4),
        Paint()
          ..color = const Color(0xFF2C1A2D)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
    canvas.drawArc(
        circle.deflate(2),
        math.pi * 1.05,
        math.pi * .8,
        false,
        Paint()
          ..color = const Color(0xEEFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
