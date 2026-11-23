import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/species.dart';

class FloraPalette {
  static const background = Color(0xFFF6F7F1);
  static const ink = Color(0xFF162D25);
  static const forest = Color(0xFF19483B);
  static const muted = Color(0xFF6C7D72);
  static const line = Color(0xFFE4EAE1);
  static const lime = Color(0xFFD7F45D);
  static const coral = Color(0xFFFFA08D);
  static const blue = Color(0xFFBADDF0);
  static const lilac = Color(0xFFE2D8F7);
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
    return DecoratedBox(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: FloraPalette.line))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(children: [
            _item(0, Icons.local_florist_outlined, Icons.local_florist,
                'Plantdex'),
            _item(1, Icons.menu_book_outlined, Icons.menu_book, 'Journal'),
            Expanded(
                child: Center(
                    child: Semantics(
              button: true,
              label: 'Scan a plant',
              child: InkWell(
                onTap: onScan,
                customBorder: const CircleBorder(),
                child: Transform.translate(
                  offset: const Offset(0, -12),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                        color: FloraPalette.lime,
                        shape: BoxShape.circle,
                        border: Border.all(color: FloraPalette.ink, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 30, color: FloraPalette.ink),
                  ),
                ),
              ),
            ))),
            _item(2, Icons.bolt_outlined, Icons.bolt, 'Quests'),
            _item(3, Icons.face_outlined, Icons.face, 'You'),
          ]),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, IconData activeIcon, String label) {
    final active = selected == index;
    return Expanded(
        child: InkWell(
      onTap: () => onSelect(index),
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(active ? activeIcon : icon,
              size: 24, color: active ? FloraPalette.ink : FloraPalette.muted),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? FloraPalette.ink : FloraPalette.muted)),
        ]),
      ),
    ));
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
