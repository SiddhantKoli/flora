import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'atomic_purple_hardware_painter.dart';

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
    required this.onNextLook,
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
  final VoidCallback onNextLook;
  final bool ready;
  final bool busy;
  final String lookName;

  static const _bg = Color(0xFF14101D);

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
              final previewSide = width * .615;
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Center(
                  child: SizedBox(
                    width: width,
                    child: Column(children: [
                      _header(context),
                      const SizedBox(height: 16),
                      _case(width, previewSide),
                      SizedBox(
                          width: width,
                          height: 42,
                          child: const CustomPaint(
                              painter: _FloorReflectionPainter())),
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
            SizedBox(
                width: 30,
                height: 29,
                child: CustomPaint(painter: _PixelSproutPainter())),
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
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onPressed,
          child: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6E3B80),
                      Color(0xFF120B1A),
                      Color(0xFF211329)
                    ]),
                border: Border.all(color: const Color(0xFFF5C9FF), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x88B947DA), blurRadius: 7),
                  BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 5,
                      offset: Offset(1, 3))
                ]),
            child: icon == Icons.workspace_premium_rounded
                ? const CustomPaint(painter: _CrownPainter())
                : Icon(icon, color: const Color(0xFFF7E7FF), size: 23),
          ),
        ),
      ),
    );
  }

  Widget _case(double width, double previewSide) {
    final shellHeight = width * 530 / 360;
    final scale = width / 360;
    final previewTop = 78 * scale;
    return SizedBox(
      width: width,
      height: shellHeight,
      child: Stack(children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: IgnorePointer(
                child: CustomPaint(painter: AtomicPurpleHardwarePainter())),
          ),
        ),
        Positioned(
          left: 26,
          right: 26,
          top: 42 * scale,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD9FF),
                      Color(0xFFBB76D3),
                      Color(0xFFE9AEF2)
                    ]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFEDFF), width: 1.4),
                boxShadow: const [
                  BoxShadow(color: Color(0xAADB58EF), blurRadius: 7),
                  BoxShadow(
                      color: Color(0xAA100518),
                      blurRadius: 3,
                      offset: Offset(1, 3))
                ],
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
                gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF493059), Color(0xFF120C1C)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBB86CF), width: .8),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0xAA080310),
                      blurRadius: 4,
                      offset: Offset(1, 3))
                ],
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
          top: previewTop,
          width: previewSide,
          height: previewSide,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFD1FF),
                  Color(0xFF8D32AB),
                  Color(0xFFF486FF)
                ],
              ),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: const Color(0xFFFFC8FF), width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Color(0xEEB337D0), blurRadius: 17, spreadRadius: 2),
                BoxShadow(
                    color: Color(0x99090011),
                    blurRadius: 8,
                    offset: Offset(0, 5)),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF100816),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4F1D5D), width: 2),
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
        ),
        Positioned(
          left: 15,
          top: previewTop + previewSide * .33,
          child: _dPad(),
        ),
        Positioned(
          left: 43 * scale,
          top: 225 * scale,
          child: Column(children: [
            _tinyButton(),
            const SizedBox(height: 9),
            _tinyButton(),
          ]),
        ),
        Positioned(
          right: 14,
          top: previewTop + previewSide * .27,
          child: Column(children: [
            _smallRound('A', 'Choose a photo look', onSettings),
            const SizedBox(height: 12),
            _smallRound('B', 'Next photo look', onNextLook),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: previewTop + previewSide + 8,
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
          right: 2,
          top: previewTop + previewSide * .71,
          child: Transform.rotate(angle: -.18, child: _sticker()),
        ),
        Positioned(
          bottom: 90 * scale,
          left: 23,
          right: 23,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _miniDecoration(),
            _shutter(),
            _flipButton(),
          ]),
        ),
      ]),
    );
  }

  Widget _tinyButton() => Container(
        width: 21,
        height: 21,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
                center: Alignment(-.4, -.45),
                colors: [
                  Color(0xFFEEBBF5),
                  Color(0xFF853899),
                  Color(0xFF230B2C)
                ]),
            border: Border.all(color: const Color(0xFFFFD1FF), width: 1.4),
            boxShadow: const [
              BoxShadow(color: Color(0xAAE457F4), blurRadius: 5)
            ]),
      );

  Widget _sticker() => Container(
        width: 67,
        height: 65,
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFEE83),
                Color(0xFFEDD870),
                Color(0xFFE5A9F5)
              ]),
          border: Border.all(color: const Color(0xFFFFF5B4), width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0xAA10051A), blurRadius: 6, offset: Offset(2, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Text('FLORA',
                style: TextStyle(
                    color: Color(0xFF1D1027),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5)),
            Icon(Icons.eco_rounded, size: 12, color: Color(0xFF1D1027)),
          ]),
          const Spacer(),
          const SizedBox(
              width: 54,
              height: 23,
              child: CustomPaint(painter: _BarcodePainter())),
        ]),
      );

  Widget _dPad() => const SizedBox(
      width: 48, height: 61, child: CustomPaint(painter: _DPadPainter()));

  Widget _smallRound(String value, String label, VoidCallback onTap) =>
      Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                      center: Alignment(-.4, -.5),
                      colors: [
                        Color(0xFFB97AD2),
                        Color(0xFF623570),
                        Color(0xFF27152E)
                      ]),
                  border: Border.all(color: const Color(0xFFF6CCFF), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xAAE268F8), blurRadius: 6),
                    BoxShadow(
                        color: Color(0xAA09040D),
                        blurRadius: 4,
                        offset: Offset(2, 4))
                  ]),
              child: Text(value,
                  style: const TextStyle(
                      color: Color(0xFFFFDDFF),
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      );

  Widget _miniDecoration() => Container(
        width: 54,
        height: 54,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [
              Color(0xFFFFDFFF),
              Color(0xFF7C298E),
              Color(0xFFED92FF)
            ]),
            boxShadow: const [
              BoxShadow(color: Color(0xAAE055E8), blurRadius: 7)
            ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const CustomPaint(painter: _LeafPortraitPainter())),
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
              width: 108,
              height: 108,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(colors: [
                    Color(0xFFFFD5FF),
                    Color(0xFF722E91),
                    Color(0xFFFFB8FF),
                    Color(0xFF4E1C67),
                    Color(0xFFFFD5FF)
                  ]),
                  boxShadow: const [
                    BoxShadow(color: Color(0xCCE44BFA), blurRadius: 17),
                    BoxShadow(
                        color: Color(0xAA0C0412),
                        blurRadius: 9,
                        offset: Offset(0, 5))
                  ]),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF351240),
                    border:
                        Border.all(color: const Color(0xFFFFD6FF), width: 2)),
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                          center: Alignment(-.3, -.35),
                          colors: [
                            Color(0xFFF0FF72),
                            Color(0xFFD6F451),
                            Color(0xFFB2DA23)
                          ]),
                      border:
                          Border.all(color: const Color(0xFFF9FF93), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x88E1FF30), blurRadius: 12)
                      ]),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                              strokeWidth: 3, color: Color(0xFF23341B)))
                      : const Icon(Icons.eco_rounded,
                          size: 43, color: Color(0xFF15231B)),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _flipButton() => Semantics(
        button: true,
        label: 'Switch front or rear camera',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy ? null : onFlip,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF793A91),
                        Color(0xFF230D2E),
                        Color(0xFF40204E)
                      ]),
                  border: Border.all(color: const Color(0xFFFFCBFF), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xBBCE4AF2), blurRadius: 8),
                    BoxShadow(
                        color: Color(0xAA09040D),
                        blurRadius: 4,
                        offset: Offset(2, 4))
                  ]),
              child: const Icon(Icons.cameraswitch_outlined,
                  size: 29, color: Colors.white),
            ),
          ),
        ),
      );
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

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const widths = [
      2.0,
      1.0,
      3.0,
      1.0,
      2.0,
      3.0,
      1.0,
      2.0,
      1.0,
      3.0,
      1.0,
      2.0,
      2.0,
      1.0,
      3.0,
      1.0,
      2.0,
      1.0,
      2.0
    ];
    var x = 0.0;
    for (final width in widths) {
      canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height - (x % 3)),
          Paint()..color = const Color(0xFF211527));
      x += width + 1;
      if (x >= size.width) break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LeafPortraitPainter extends CustomPainter {
  const _LeafPortraitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
        bounds,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.2, -.3),
            radius: 1.15,
            colors: [Color(0xFF7AB528), Color(0xFF245823), Color(0xFF0E3018)],
          ).createShader(bounds));
    for (final p in const [Offset(7, 9), Offset(42, 8), Offset(46, 40)]) {
      canvas.drawCircle(
          p,
          8,
          Paint()
            ..color = const Color(0x445BEB4C)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    final leaf = Path()
      ..moveTo(size.width * .18, size.height * .82)
      ..cubicTo(size.width * .22, size.height * .2, size.width * .55,
          size.height * .08, size.width * .86, size.height * .16)
      ..cubicTo(size.width * .89, size.height * .63, size.width * .5,
          size.height * .89, size.width * .18, size.height * .82)
      ..close();
    canvas.drawPath(
        leaf,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFCCED72), Color(0xFF73B82D), Color(0xFF317524)],
          ).createShader(bounds));
    canvas.drawPath(
        leaf,
        Paint()
          ..color = const Color(0xFFDBF5A8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8);
    final vein = Paint()
      ..color = const Color(0x99E8F7AD)
      ..strokeWidth = 1.3;
    canvas.drawLine(Offset(size.width * .2, size.height * .82),
        Offset(size.width * .79, size.height * .2), vein);
    for (var i = 0; i < 4; i++) {
      final t = i / 5 + .18;
      final x = size.width * (.2 + .59 * t);
      final y = size.height * (.82 - .62 * t);
      canvas.drawLine(Offset(x, y), Offset(x - 8, y - 9), vein);
      canvas.drawLine(Offset(x, y), Offset(x + 8, y + 5), vein);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DPadPainter extends CustomPainter {
  const _DPadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(16, 2)
      ..lineTo(32, 2)
      ..lineTo(32, 20)
      ..lineTo(47, 20)
      ..lineTo(47, 41)
      ..lineTo(32, 41)
      ..lineTo(32, 59)
      ..lineTo(16, 59)
      ..lineTo(16, 41)
      ..lineTo(1, 41)
      ..lineTo(1, 20)
      ..lineTo(16, 20)
      ..close();
    canvas.drawPath(
        path.shift(const Offset(1, 3)),
        Paint()
          ..color = const Color(0xCC0C0412)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9E64B5), Color(0xFF3A1A48), Color(0xFF1A0D23)],
          ).createShader(Offset.zero & size));
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFF7C9FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7);
    canvas.drawLine(
        const Offset(17, 5),
        const Offset(31, 5),
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..strokeWidth = 1.2);
    final arrow = Paint()..color = const Color(0xFFCA9DD9);
    for (final points in [
      [const Offset(24, 8), const Offset(21, 14), const Offset(27, 14)],
      [const Offset(24, 53), const Offset(21, 47), const Offset(27, 47)],
      [const Offset(7, 30), const Offset(13, 27), const Offset(13, 33)],
      [const Offset(41, 30), const Offset(35, 27), const Offset(35, 33)],
    ]) {
      canvas.drawPath(Path()..addPolygon(points, true), arrow);
    }
    canvas.drawCircle(
        const Offset(24, 30), 6, Paint()..color = const Color(0xFF150A20));
    canvas.drawCircle(
        const Offset(23, 29), 4, Paint()..color = const Color(0xFF9A64AD));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final crown = Path()
      ..moveTo(10, 29)
      ..lineTo(7, 15)
      ..lineTo(14, 20)
      ..lineTo(21, 10)
      ..lineTo(28, 20)
      ..lineTo(35, 15)
      ..lineTo(32, 29)
      ..close();
    canvas.drawPath(
        crown,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFF4FF65), Color(0xFFD6F451), Color(0xFF91C318)],
          ).createShader(Offset.zero & size));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(10, 31, 22, 3), const Radius.circular(1)),
        Paint()..color = const Color(0xFFD6F451));
    for (final point in const [Offset(7, 14), Offset(21, 9), Offset(35, 14)]) {
      canvas.drawCircle(point, 2.2, Paint()..color = const Color(0xFFFFFFA5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PixelSproutPainter extends CustomPainter {
  const _PixelSproutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pixel = Paint()..color = const Color(0xFFD6F451);
    for (final rect in const [
      Rect.fromLTWH(3, 8, 5, 5),
      Rect.fromLTWH(8, 10, 5, 5),
      Rect.fromLTWH(12, 14, 5, 5),
      Rect.fromLTWH(19, 4, 5, 5),
      Rect.fromLTWH(23, 2, 5, 5),
      Rect.fromLTWH(17, 9, 5, 5),
      Rect.fromLTWH(13, 19, 5, 5),
      Rect.fromLTWH(14, 24, 4, 5),
    ]) {
      canvas.drawRect(rect, pixel);
    }
    canvas.drawLine(
        const Offset(16, 25),
        const Offset(17, 29),
        Paint()
          ..color = const Color(0xFF85B831)
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloorReflectionPainter extends CustomPainter {
  const _FloorReflectionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .08, -8, size.width * .84, size.height * .8),
        Paint()
          ..shader = const RadialGradient(colors: [
            Color(0xAAAC35D9),
            Color(0x225B1472),
            Color(0x00140B1A),
          ]).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    for (final x in [.17, .5, .81]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size.width * x, 5), width: 34, height: 8),
          Paint()
            ..color = const Color(0x99F65CFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
