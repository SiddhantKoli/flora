import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual shell for FLORA's in-app camera. Capture and storage stay in the
/// parent screen so changing the shell cannot bypass photo review.
class AtomicPurpleCameraSkin extends StatelessWidget {
  const AtomicPurpleCameraSkin({
    super.key,
    required this.preview,
    required this.onCapture,
    required this.onBack,
    required this.onFlip,
    required this.onSettings,
    required this.onSkins,
    required this.ready,
    required this.busy,
    this.lookName = 'Natural',
  });

  final Widget preview;
  final VoidCallback onCapture;
  final VoidCallback onBack;
  final VoidCallback onFlip;
  final VoidCallback onSettings;
  final VoidCallback onSkins;
  final bool ready;
  final bool busy;
  final String lookName;

  static const _bg = Color(0xFF14101D);
  static const _purple = Color(0xFF9B5CC9);
  static const _lavender = Color(0xFFDFB8FD);
  static const _lime = Color(0xFFD6F451);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.15),
                radius: 1.2,
                colors: [Color(0xFF2F1A3F), _bg],
              ),
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              // The preview is always 1:1. The device shell grows vertically,
              // and the entire screen scrolls rather than clipping on short phones.
              final width = math.min(constraints.maxWidth - 12, 490.0);
              final previewSide = width - 98;
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Center(
                  child: SizedBox(
                    width: width,
                    child: Column(children: [
                      _header(context),
                      const SizedBox(height: 16),
                      _case(width, previewSide),
                      const SizedBox(height: 20),
                      Text('ATOMIC PURPLE  /  CAMERA SKIN 01',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            letterSpacing: 1.25,
                            fontSize: 10,
                            color: _lavender.withValues(alpha: .65),
                          )),
                      const SizedBox(height: 18),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 12, 7, 0),
      child: Row(children: [
        _topIcon(Icons.arrow_back_rounded, 'Back', onBack),
        const Spacer(),
        Column(mainAxisSize: MainAxisSize.min, children: const [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.spa_rounded, color: _lime, size: 25),
            SizedBox(width: 4),
            Text('FLORA',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                    color: Color(0xFFF7E7FF))),
          ]),
        ]),
        const Spacer(),
        _topIcon(Icons.workspace_premium_rounded, 'Camera style', onSkins),
        const SizedBox(width: 8),
        _topIcon(Icons.settings_rounded, 'Photo looks', onSettings),
      ]),
    );
  }

  Widget _topIcon(IconData icon, String label, VoidCallback onPressed) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFF281936),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: const BorderSide(color: _purple, width: 1.3),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onPressed,
          child: SizedBox(
            width: 43,
            height: 43,
            child: Icon(icon, color: const Color(0xFFF7E7FF), size: 23),
          ),
        ),
      ),
    );
  }

  Widget _case(double width, double previewSide) {
    final shellHeight = previewSide + 262;
    return SizedBox(
      width: width,
      height: shellHeight,
      child: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF452755),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFFCB94F8), width: 3),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xAA864CA4),
                  Color(0xFF3A214A),
                  Color(0xCC704587)
                ],
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x885C2593), blurRadius: 24, spreadRadius: 2),
                BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 20,
                    offset: Offset(0, 8)),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child:
                IgnorePointer(child: CustomPaint(painter: _CircuitPainter())),
          ),
        ),
        Positioned(left: 19, top: 21, child: _screw()),
        Positioned(right: 19, top: 21, child: _screw()),
        Positioned(left: 19, bottom: 21, child: _screw()),
        Positioned(right: 19, bottom: 21, child: _screw()),
        Positioned(
          left: 26,
          right: 26,
          top: 24,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFCB9EE8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF3D8FF)),
              ),
              child: const Text('FLORA CAM',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    letterSpacing: .8,
                    color: Color(0xFF23142A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  )),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF241629),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Icon(Icons.circle,
                    size: 9,
                    color: ready ? const Color(0xFFFF5A6A) : Colors.grey),
                const SizedBox(width: 6),
                Text(ready ? 'LIVE' : 'WAIT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),
        Positioned(
          left: (width - previewSide) / 2,
          top: 72,
          width: previewSide,
          height: previewSide,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF130E17),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _lavender, width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x994E187B), blurRadius: 12, spreadRadius: 2)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(fit: StackFit.expand, children: [
                preview,
                IgnorePointer(
                    child: CustomPaint(painter: _ViewfinderPainter())),
              ]),
            ),
          ),
        ),
        Positioned(
          left: 15,
          top: 72 + (previewSide / 2) - 30,
          child: _dPad(),
        ),
        Positioned(
          right: 14,
          top: 72 + (previewSide / 2) - 40,
          child: Column(children: [
            _smallRound('A'),
            const SizedBox(height: 12),
            _smallRound('B'),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: previewSide + 80,
          child: Center(
            child: Text('${lookName.toUpperCase()} LOOK',
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                    color: Color(0xFFECD2FC))),
          ),
        ),
        Positioned(
          bottom: 54,
          left: 23,
          right: 23,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _miniDecoration(),
            _shutter(),
            _flipButton(),
          ]),
        ),
        Positioned(
          bottom: 25,
          left: 0,
          right: 0,
          child: Center(
            child: Text('TRANSPARENT EDITION',
                style: TextStyle(
                    fontFamily: 'monospace',
                    color: _lavender.withValues(alpha: .74),
                    fontSize: 9,
                    letterSpacing: 1.6)),
          ),
        ),
      ]),
    );
  }

  Widget _screw() => Container(
        width: 17,
        height: 17,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFBDA2C7),
          border: Border.all(color: const Color(0xFFEDD7F6), width: 2),
        ),
        child:
            const Icon(Icons.add_rounded, size: 12, color: Color(0xFF352639)),
      );

  Widget _dPad() => Opacity(
        opacity: .87,
        child: SizedBox(
          width: 38,
          height: 64,
          child: Stack(alignment: Alignment.center, children: [
            Container(
                width: 19,
                height: 60,
                decoration: BoxDecoration(
                    color: const Color(0xFF25172F),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _lavender))),
            Container(
                width: 38,
                height: 19,
                decoration: BoxDecoration(
                    color: const Color(0xFF25172F),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _lavender))),
            const Icon(Icons.circle, color: Color(0xFFB58AD0), size: 11),
          ]),
        ),
      );

  Widget _smallRound(String value) => Container(
        width: 37,
        height: 37,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF694579),
          border: Border.all(color: _lavender, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x880D0912), offset: Offset(1, 3), blurRadius: 2)
          ],
        ),
        child: Text(value,
            style: const TextStyle(
                color: Color(0xFFEBD7F4),
                fontSize: 17,
                fontWeight: FontWeight.bold)),
      );

  Widget _miniDecoration() => Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFF301D3C),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _lavender, width: 2),
        ),
        child: const Icon(Icons.local_florist_rounded, color: _lime, size: 29),
      );

  Widget _shutter() => Semantics(
        button: true,
        enabled: ready && !busy,
        label: 'Take plant photo with $lookName look',
        child: GestureDetector(
          onTap: ready && !busy ? onCapture : null,
          child: Opacity(
            opacity: ready && !busy ? 1 : .5,
            child: Container(
              width: 99,
              height: 99,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF57316D),
                border: Border.all(color: _lavender, width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x885B2B8A), blurRadius: 12, spreadRadius: 2)
                ],
              ),
              child: Container(
                decoration:
                    const BoxDecoration(shape: BoxShape.circle, color: _lime),
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Color(0xFF23341B)))
                    : const Icon(Icons.eco_rounded,
                        size: 43, color: Color(0xFF23341B)),
              ),
            ),
          ),
        ),
      );

  Widget _flipButton() => Semantics(
        button: true,
        label: 'Switch front or rear camera',
        child: Material(
          color: const Color(0xFF352044),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
              side: const BorderSide(color: _lavender, width: 1.5)),
          child: InkWell(
            onTap: busy ? null : onFlip,
            borderRadius: BorderRadius.circular(13),
            child: const SizedBox(
                width: 55,
                height: 55,
                child: Icon(Icons.cameraswitch_outlined,
                    size: 29, color: Colors.white)),
          ),
        ),
      );
}

class _CircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x669F83B9)
      ..strokeWidth = 1.15
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = const Color(0xAAE0B9FC);
    for (int i = 0; i < 25; i++) {
      final y = 19.0 + i * 23.0;
      final fromLeft = i.isEven;
      final start = fromLeft ? 0.0 : size.width;
      final mid =
          fromLeft ? 36.0 + (i % 3) * 9 : size.width - 36.0 - (i % 3) * 9;
      final path = Path()
        ..moveTo(start, y)
        ..lineTo(mid, y)
        ..lineTo(mid, y + 9);
      canvas.drawPath(path, line);
      canvas.drawCircle(Offset(mid, y + 9), 2, dot);
    }
    final chip = Paint()..color = const Color(0x88301B3D);
    for (int i = 0; i < 6; i++) {
      final x = i.isEven ? 26.0 : size.width - 47.0;
      final y = 70.0 + i * 73;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, 21, 32), const Radius.circular(3)),
          chip);
      canvas.drawRect(Rect.fromLTWH(x + 5, y + 6, 11, 3), line);
    }
    final shine = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(8, 7, size.width - 16, size.height - 14),
            const Radius.circular(32)),
        Paint()
          ..color = const Color(0x00FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawLine(const Offset(30, 10), Offset(size.width - 45, 10),
        shine..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x4DFFFFFF)
      ..strokeWidth = .7;
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), grid);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), grid);
    final corner = Paint()
      ..color = const Color(0xFFD6F451)
      ..strokeWidth = 3.3
      ..strokeCap = StrokeCap.round;
    const inset = 11.0, length = 18.0;
    void drawCorner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * length, y), corner);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * length), corner);
    }

    drawCorner(inset, inset, 1, 1);
    drawCorner(size.width - inset, inset, -1, 1);
    drawCorner(inset, size.height - inset, 1, -1);
    drawCorner(size.width - inset, size.height - inset, -1, -1);
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width / 2 - 10, size.height / 2),
        Offset(size.width / 2 + 10, size.height / 2), p);
    canvas.drawLine(Offset(size.width / 2, size.height / 2 - 10),
        Offset(size.width / 2, size.height / 2 + 10), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
