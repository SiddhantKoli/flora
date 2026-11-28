import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../ui/flora_design.dart';

class FieldCameraShell extends StatelessWidget {
  const FieldCameraShell(
      {super.key,
      required this.preview,
      required this.ready,
      required this.busy,
      required this.lookName,
      required this.onCapture,
      required this.onFlip,
      required this.onBack,
      required this.onSettings,
      required this.onNextLook});
  final Widget preview;
  final bool ready;
  final bool busy;
  final String lookName;
  final VoidCallback onCapture;
  final VoidCallback onFlip;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onNextLook;

  static const cameraBg = Color(0xFF081718);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Widget shutter = Semantics(
        button: true,
        enabled: ready,
        label: busy ? 'Saving photo' : 'Take plant photo',
        child: Material(
            color: ready ? FloraPalette.coral : const Color(0xFF667575),
            shape: const CircleBorder(),
            child: InkWell(
                onTap: ready ? onCapture : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                    width: 82,
                    height: 82,
                    child: Center(
                        child: busy
                            ? const SizedBox(
                                width: 27,
                                height: 27,
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: FloraPalette.ink))
                            : const Icon(Icons.photo_camera_rounded,
                                color: FloraPalette.ink, size: 34))))));
    if (!reduceMotion)
      shutter = shutter.animate().fadeIn(duration: 280.ms).scale(
          begin: const Offset(.82, .82),
          duration: 420.ms,
          curve: Curves.easeOutBack);
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: cameraBg,
            systemNavigationBarIconBrightness: Brightness.light),
        child: Scaffold(
          backgroundColor: cameraBg,
          body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
            final width = math.min(constraints.maxWidth, 540.0);
            return SingleChildScrollView(
                child: Center(
                    child: SizedBox(
                        width: width,
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    IconButton(
                                        onPressed: onBack,
                                        tooltip: 'Back',
                                        icon: const Icon(
                                            Icons.arrow_back_rounded,
                                            color: Colors.white)),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                        child: Text('FLORA / FIELD CAM',
                                            style: TextStyle(
                                                fontFamily: 'SpaceGrotesk',
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 17,
                                                letterSpacing: -.2))),
                                    IconButton(
                                        onPressed: onSettings,
                                        tooltip: 'Photo looks',
                                        icon: const Icon(Icons.tune_rounded,
                                            color: Colors.white)),
                                  ]),
                                  const SizedBox(height: 13),
                                  Row(children: [
                                    Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                            color: FloraPalette.coral,
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text('LIVE VIEW',
                                        style: FloraType.caption
                                            .copyWith(color: Colors.white)),
                                    const Spacer(),
                                    Text('1:1 FRAME',
                                        style: FloraType.caption.copyWith(
                                            color: const Color(0xFFACBDBA))),
                                  ]),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                preview,
                                                const IgnorePointer(
                                                    child: CustomPaint(
                                                        painter:
                                                            _ViewfinderPainter())),
                                              ]))),
                                  const SizedBox(height: 16),
                                  Material(
                                      color: const Color(0xFF173133),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                          onTap: onNextLook,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 13),
                                              child: Row(children: [
                                                const Icon(
                                                    Icons
                                                        .filter_vintage_outlined,
                                                    color: FloraPalette.mint,
                                                    size: 21),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                    child: Text(lookName,
                                                        style: FloraType.body
                                                            .copyWith(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800))),
                                                Text('Change look',
                                                    style: FloraType.caption
                                                        .copyWith(
                                                            color: const Color(
                                                                0xFFB4C8C4))),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                    Icons
                                                        .arrow_forward_ios_rounded,
                                                    color: Colors.white,
                                                    size: 14),
                                              ])))),
                                  const SizedBox(height: 18),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _sideButton(Icons.tune_rounded,
                                            'All photo looks', onSettings),
                                        shutter,
                                        _sideButton(Icons.cameraswitch_outlined,
                                            'Flip camera', onFlip),
                                      ]),
                                  const SizedBox(height: 15),
                                  Center(
                                      child: Text(
                                          'Take a photo. Name the plant next.',
                                          style: FloraType.caption.copyWith(
                                              color: const Color(0xFFD0DEDA)))),
                                ])))));
          })),
        ));
  }

  Widget _sideButton(IconData icon, String label, VoidCallback callback) =>
      IconButton(
          onPressed: callback,
          tooltip: label,
          style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF173133),
              minimumSize: const Size(54, 54)),
          icon: Icon(icon, size: 25, color: Colors.white));
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final faint = Paint()
      ..color = Colors.white.withValues(alpha: .24)
      ..strokeWidth = .7;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), faint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), faint);
    }
    final guide = Paint()
      ..color = FloraPalette.signal
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const margin = 17.0;
    const length = 24.0;
    for (final left in [true, false]) {
      for (final top in [true, false]) {
        final x = left ? margin : size.width - margin;
        final y = top ? margin : size.height - margin;
        canvas.drawLine(
            Offset(x, y), Offset(x + (left ? length : -length), y), guide);
        canvas.drawLine(
            Offset(x, y), Offset(x, y + (top ? length : -length)), guide);
      }
    }
    final cross = Paint()
      ..color = Colors.white.withValues(alpha: .8)
      ..strokeWidth = 1.6;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(center.translate(-9, 0), center.translate(9, 0), cross);
    canvas.drawLine(center.translate(0, -9), center.translate(0, 9), cross);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
