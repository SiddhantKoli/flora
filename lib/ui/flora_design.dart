import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/species.dart';

class FloraPalette {
  static const background = Color(0xFFF2F4F1);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF101B1A);
  static const night = Color(0xFF102B2C);
  static const signal = Color(0xFF345BFF);
  static const coral = Color(0xFFFF6A4C);
  static const mint = Color(0xFFCEE7D5);
  static const muted = Color(0xFF53625E);
  static const line = Color(0xFFD7DFDA);
  static const forest = night;
  static const lime = mint;
  static const blue = Color(0xFFDCE9FF);
  static const lilac = Color(0xFFE8E6F1);
}

class FloraType {
  static const display = TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
      fontSize: 40,
      height: 1.02,
      letterSpacing: -1.8,
      color: FloraPalette.ink);
  static const title = TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
      fontSize: 26,
      height: 1.08,
      letterSpacing: -0.9,
      color: FloraPalette.ink);
  static const body = TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w500,
      fontSize: 15,
      height: 1.42,
      color: FloraPalette.ink);
  static const caption = TextStyle(
      fontFamily: 'DMSans',
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 1.3,
      color: FloraPalette.muted);
}

class FloraNavBar extends StatelessWidget {
  const FloraNavBar(
      {super.key,
      required this.selected,
      required this.onSelect,
      required this.onScan});

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Widget camera = Material(
      color: FloraPalette.coral,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onScan,
        borderRadius: BorderRadius.circular(17),
        child: const SizedBox(
            width: 60,
            height: 58,
            child: Icon(Icons.photo_camera_rounded,
                color: FloraPalette.ink, size: 29)),
      ),
    );
    if (!reduceMotion) {
      camera = camera.animate().fadeIn(duration: 250.ms).scale(
          begin: const Offset(.84, .84),
          duration: 360.ms,
          curve: Curves.easeOutBack);
    }
    return DecoratedBox(
        decoration: const BoxDecoration(
            color: FloraPalette.surface,
            border: Border(top: BorderSide(color: FloraPalette.line))),
        child: SafeArea(
            top: false,
            child: SizedBox(
                height: 76,
                child: Row(children: [
                  _item(0, Icons.grid_view_rounded, 'Explore'),
                  _item(1, Icons.book_outlined, 'Journal'),
                  Expanded(
                      child: Center(
                          child: Semantics(
                              button: true,
                              label: 'Add a plant',
                              child: camera))),
                  _item(2, Icons.bolt_outlined, 'Quests'),
                  _item(3, Icons.person_outline_rounded, 'You'),
                ]))));
  }

  Widget _item(int index, IconData icon, String label) {
    final active = selected == index;
    return Expanded(
        child: Semantics(
            button: true,
            selected: active,
            label: label,
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    onTap: () => onSelect(index),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: active ? 26 : 0,
                              height: 3,
                              decoration: BoxDecoration(
                                  color: FloraPalette.signal,
                                  borderRadius: BorderRadius.circular(3))),
                          const SizedBox(height: 7),
                          Icon(icon,
                              size: 24,
                              color: active
                                  ? FloraPalette.ink
                                  : FloraPalette.muted),
                          const SizedBox(height: 3),
                          Text(label,
                              style: TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: active
                                      ? FloraPalette.ink
                                      : FloraPalette.muted)),
                        ])))));
  }
}

class PlantIllustration extends StatelessWidget {
  const PlantIllustration(
      {super.key, required this.species, this.muted = false, this.scale = 1});
  final Species species;
  final bool muted;
  final double scale;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _PlantPainter(species: species, muted: muted),
        size: Size(160 * scale, 180 * scale),
      );
}

class _PlantPainter extends CustomPainter {
  const _PlantPainter({required this.species, required this.muted});
  final Species species;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 160;
    canvas.save();
    canvas.scale(unit, size.height / 180);
    final leaf = muted ? const Color(0xFF8DAB92) : const Color(0xFF245B45);
    final leafLight = muted ? const Color(0xFFB0C4AE) : const Color(0xFF438467);
    final stem = Paint()
      ..color = leaf
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (species.id == 'aloe-vera') {
      for (var i = 0; i < 7; i++) {
        final angle = (i - 3) * 0.26;
        final tip = Offset(80 + math.sin(angle) * 78, 48 + (i - 3).abs() * 14);
        final path = Path()
          ..moveTo(78, 164)
          ..quadraticBezierTo(55 + i * 7, 104, tip.dx, tip.dy)
          ..quadraticBezierTo(85 + i * 4, 115, 83, 164)
          ..close();
        canvas.drawPath(path, Paint()..color = i.isEven ? leaf : leafLight);
      }
    } else {
      final path = Path()
        ..moveTo(80, 166)
        ..cubicTo(74, 119, 97, 78, 83, 24);
      canvas.drawPath(path, stem);
      final isMonstera = species.id == 'monstera-deliciosa';
      final isRubber = species.id == 'ficus-elastica';
      final isPothos = species.id == 'epipremnum-aureum';
      final isNeem = species.id == 'azadirachta-indica';
      for (var i = 0; i < 5; i++) {
        final y = 135.0 - i * 25;
        final right = i.isEven;
        final base = Offset(82 + (i.isOdd ? 3 : -2), y);
        final tip =
            Offset(right ? 143.0 - i * 3 : 20.0 + i * 3, y - 36 - (i % 2) * 3);
        final upper = Offset(right ? 115 : 43, y - (isRubber ? 56 : 50));
        final lower = Offset(right ? 121 : 40, y + (isRubber ? 2 : -7));
        final blade = Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(upper.dx, upper.dy, tip.dx, tip.dy);
        if (isPothos) {
          blade
            ..quadraticBezierTo(
                right ? 125 : 35, y - 24, right ? 113 : 47, y - 18)
            ..quadraticBezierTo(lower.dx, lower.dy, base.dx, base.dy);
        } else {
          blade.quadraticBezierTo(lower.dx, lower.dy, base.dx, base.dy);
        }
        blade.close();
        canvas.drawPath(blade, Paint()..color = i.isEven ? leaf : leafLight);
        canvas.drawLine(
            base,
            tip,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.24)
              ..strokeWidth = 1.4);
        if (isMonstera) {
          final slitPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.4)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
          final direction = right ? 1.0 : -1.0;
          for (var j = 0; j < 3; j++) {
            final x = base.dx + direction * (18 + j * 11);
            final slitY = y - 13 - j * 5;
            canvas.drawLine(Offset(x, slitY),
                Offset(x + direction * 7, slitY - 10), slitPaint);
          }
        }
        if (isNeem) {
          final twigPaint = Paint()
            ..color = leaf
            ..strokeWidth = 1.4;
          final direction = right ? 1.0 : -1.0;
          for (var j = 0; j < 3; j++) {
            final x = base.dx + direction * (13 + j * 13);
            final twigY = y - 8 - j * 7;
            canvas.drawLine(Offset(x, twigY),
                Offset(x + direction * 9, twigY - 12), twigPaint);
            canvas.drawOval(
                Rect.fromCenter(
                    center: Offset(x + direction * 10, twigY - 13),
                    width: 12,
                    height: 5),
                Paint()..color = leafLight);
          }
        }
      }
      if (species.id.contains('hibiscus') ||
          species.id.contains('bougainvillea')) {
        final petalColor = species.id.contains('hibiscus')
            ? FloraPalette.coral
            : FloraPalette.lilac;
        canvas.save();
        canvas.translate(82, 30);
        for (var i = 0; i < 5; i++) {
          canvas.rotate(math.pi * 2 / 5);
          final petal = Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(-16, -23, 0, -39)
            ..quadraticBezierTo(16, -23, 0, 0)
            ..close();
          canvas.drawPath(
              petal, Paint()..color = muted ? leafLight : petalColor);
        }
        canvas.drawCircle(Offset.zero, 7, Paint()..color = FloraPalette.lime);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) =>
      oldDelegate.species != species || oldDelegate.muted != muted;
}
