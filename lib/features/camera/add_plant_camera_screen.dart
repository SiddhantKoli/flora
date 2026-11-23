import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'camera_look.dart';
import 'look_baker.dart';
import '../../ui/flora_design.dart';

class CameraPalette {
  static const cream = FloraPalette.background;
  static const forest = FloraPalette.forest;
  static const forestSoft = Color(0xFF245544);
  static const lime = FloraPalette.lime;
  static const coral = FloraPalette.coral;
  static const lilac = Color(0xFFE4DDF5);
}

/// "Add a plant" camera. Hands the result to FLORA's existing review flow via
/// [onPhotoReady]. It does not identify plants; the user picks one manually
/// on the review step.
class AddPlantCameraScreen extends StatefulWidget {
  const AddPlantCameraScreen({
    super.key,
    required this.onPhotoReady,
    this.initialLookId = 'natural',
  });

  final void Function(CapturedPlantPhoto photo) onPhotoReady;
  final String initialLookId;

  @override
  State<AddPlantCameraScreen> createState() => _AddPlantCameraScreenState();
}

class _AddPlantCameraScreenState extends State<AddPlantCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _errorMessage;
  bool _starting = false;
  bool _busy = false;
  late CameraLook _look = lookById(widget.initialLookId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      if (c != null) {
        _controller = null;
        c.dispose();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_starting || _controller != null) return;
    _starting = true;
    if (mounted) setState(() => _errorMessage = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'No camera found.');
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
    } on CameraException catch (e) {
      if (mounted) setState(() => _errorMessage = _messageFor(e));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage =
            'The camera couldn’t start. Please try again, or choose a photo from your gallery.');
      }
    } finally {
      _starting = false;
    }
  }

  String _messageFor(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'FLORA needs camera access to add a plant photo. You can allow it in your phone’s Settings, or choose a photo from your gallery instead.';
      default:
        return 'The camera couldn’t start. Please try again, or choose a photo from your gallery.';
    }
  }

  void _setLook(CameraLook look) {
    if (look.id == _look.id) return;
    HapticFeedback.selectionClick();
    setState(() => _look = look);
  }

  void _nextLook() {
    final i = kCameraLooks.indexWhere((l) => l.id == _look.id);
    _setLook(kCameraLooks[(i + 1) % kCameraLooks.length]);
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null ||
        !c.value.isInitialized ||
        _busy ||
        c.value.isTakingPicture) {
      return;
    }
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      final shot = await c.takePicture();
      String? processed;
      if (!_look.isNatural) {
        try {
          processed = await LookBaker.bake(
            originalPath: shot.path,
            lookId: _look.id,
          );
        } catch (_) {
          _snack('Couldn’t apply the look, so your original photo was kept.');
        }
      }
      if (!mounted) return;
      widget.onPhotoReady(CapturedPlantPhoto(
        originalPath: shot.path,
        processedPath: processed,
        lookId: processed == null ? 'natural' : _look.id,
      ));
    } on CameraException {
      _snack('Couldn’t take the photo. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      // Looks apply to camera captures only; gallery photos stay untouched.
      widget.onPhotoReady(CapturedPlantPhoto(originalPath: picked.path));
    } catch (_) {
      _snack('Couldn’t open your gallery. Please try again.');
    }
  }

  void _showAbout() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CameraPalette.cream,
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Text(
          'Looks are creative effects that run inside FLORA, inspired by the '
          'general feel of compact digital cameras like the Canon IXUS and '
          'Sony Cyber-shot. They aren’t Canon or Sony modes and don’t '
          'reproduce those cameras’ processing.\n\n'
          'FLORA doesn’t identify plants. You choose the plant yourself on '
          'the next step.',
          style:
              TextStyle(fontSize: 15, height: 1.4, color: CameraPalette.forest),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final anim =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 180);

    return Scaffold(
      backgroundColor: CameraPalette.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final compact = box.maxHeight < 660;
            final reserved = compact ? 340.0 : 380.0;
            final frameSide = math
                .min(box.maxWidth - 28, box.maxHeight - reserved)
                .clamp(220.0, 560.0);

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _header(),
                    _cameraShell(frameSide, anim),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            iconSize: 28,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded,
                color: CameraPalette.forest),
          ),
          const Expanded(
            child: Text(
              'Add a plant',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CameraPalette.forest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraShell(double side, Duration anim) {
    return Container(
      width: side,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: CameraPalette.forest,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF103A2D), width: 3),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 9)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                _screw(),
                const SizedBox(width: 10),
                const Text('FLORA',
                    style: TextStyle(
                        color: CameraPalette.lime,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
                const Spacer(),
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: CameraPalette.coral, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('FIELD CAM',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(width: 10),
                _screw(),
              ],
            ),
          ),
          _cameraBody(side - 26),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
            decoration: BoxDecoration(
              color: CameraPalette.lilac,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _lookLabel(),
                const SizedBox(height: 8),
                _lookChips(anim),
                const SizedBox(height: 8),
                _controls(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  7,
                  (_) => Container(
                      width: 12,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                          color: CameraPalette.forestSoft,
                          borderRadius: BorderRadius.circular(3))))),
        ],
      ),
    );
  }

  Widget _screw() => Container(
        width: 13,
        height: 13,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CameraPalette.forestSoft,
            border: Border.all(color: const Color(0xFF6C9A86), width: 1.5)),
        child: Container(width: 7, height: 1.5, color: const Color(0xFFB0CFB8)),
      );

  Widget _cameraBody(double side) {
    final inner = side - 16;
    return Semantics(
      container: true,
      label: 'Camera viewfinder. ${_look.name} look preview.',
      child: Container(
        width: side,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0E3328),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF386A55), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusDisplay(),
            const SizedBox(height: 8),
            SizedBox(
              width: inner,
              height: inner,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _previewLayer(),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                        painter: _CornerPainter(CameraPalette.lime)),
                  ),
                  if (_busy)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: const Color(0xAA14352A),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: CameraPalette.lime),
                            const SizedBox(height: 12),
                            Text(
                              _look.isNatural
                                  ? 'Saving photo…'
                                  : 'Applying look…',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDisplay() {
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: CameraPalette.lime,
    );
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CameraPalette.forestSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExcludeSemantics(
        child: Row(
          children: [
            const Text('FLORA CAM', style: mono),
            const Spacer(),
            Text(_look.shortCode, style: mono),
            const Spacer(),
            const Text('FRAME 1:1', style: mono),
          ],
        ),
      ),
    );
  }

  Widget _previewLayer() {
    if (_errorMessage != null) {
      return Container(
        color: CameraPalette.forestSoft,
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: CameraPalette.lime, size: 40),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.35),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: CameraPalette.lime,
                foregroundColor: CameraPalette.forest,
                minimumSize: const Size(48, 48),
              ),
              onPressed: _initCamera,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.previewSize == null) {
      return Container(
        color: CameraPalette.forestSoft,
        alignment: Alignment.center,
        child: Semantics(
          label: 'Starting camera',
          child: const CircularProgressIndicator(color: CameraPalette.lime),
        ),
      );
    }

    // previewSize is reported in landscape, so swap for portrait UI.
    final ps = c.value.previewSize!;
    Widget cam = FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: ps.height,
        height: ps.width,
        child: CameraPreview(c),
      ),
    );
    cam = ColorFiltered(
      colorFilter: ColorFilter.matrix(_look.matrix),
      child: cam,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        cam,
        if (_look.glow > 0)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [
                    Color.fromRGBO(255, 255, 255, _look.glow * 0.25),
                    const Color.fromRGBO(255, 255, 255, 0),
                  ],
                ),
              ),
            ),
          ),
        if (_look.vignette > 0)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.95,
                  stops: const [0.55, 1.0],
                  colors: [
                    const Color.fromRGBO(0, 0, 0, 0),
                    Color.fromRGBO(0, 0, 0, _look.vignette),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _lookLabel() {
    final note = _look.isNatural
        ? 'Original colors · full photo saved'
        : _look.hasGrain
            ? 'Grain added on capture · choose original on review'
            : 'Look added on capture · choose original on review';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _look.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: CameraPalette.forest,
                      ),
                    ),
                    Text(
                      _look.isNatural
                          ? _look.inspiredBy
                          : 'Inspired by ${_look.inspiredBy}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: CameraPalette.forestSoft),
                    ),
                  ],
                ),
              ),
              if (!_look.isNatural)
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: CameraPalette.forest,
                  ),
                  onPressed: () => _setLook(natural),
                  child: Semantics(
                    label: 'Switch back to the Natural look',
                    excludeSemantics: true,
                    child: const Text('Natural',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              IconButton(
                tooltip: 'About looks',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: _showAbout,
                icon: const Icon(Icons.info_outline_rounded,
                    color: CameraPalette.forest),
              ),
            ],
          ),
          Text(
            note,
            style: const TextStyle(
                fontSize: 12, height: 1.3, color: CameraPalette.forestSoft),
          ),
        ],
      ),
    );
  }

  Widget _lookChips(Duration anim) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kCameraLooks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final look = kCameraLooks[i];
          final selected = look.id == _look.id;
          return Semantics(
            button: true,
            selected: selected,
            label: '${look.name} look',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _setLook(look),
              child: AnimatedContainer(
                duration: anim,
                constraints: const BoxConstraints(minHeight: 48, minWidth: 72),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? CameraPalette.forest : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: CameraPalette.forest, width: 1.5),
                ),
                child: Text(
                  look.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? CameraPalette.lime : CameraPalette.forest,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _controls() {
    final ready = _controller?.value.isInitialized == true && !_busy;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _sideButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            semantics: 'Choose a photo from your gallery',
            onTap: _busy ? null : _pickFromGallery,
          ),
          Semantics(
            button: true,
            enabled: ready,
            label: 'Take photo with ${_look.name} look',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: ready ? _capture : null,
              child: Opacity(
                opacity: ready ? 1 : 0.5,
                child: Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CameraPalette.forest, width: 3),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CameraPalette.lime,
                    ),
                    child: const Icon(Icons.eco_rounded,
                        color: CameraPalette.forest, size: 32),
                  ),
                ),
              ),
            ),
          ),
          _sideButton(
            icon: Icons.auto_awesome_outlined,
            label: 'Next look',
            semantics: 'Next look. Current look is ${_look.name}',
            onTap: _nextLook,
          ),
        ],
      ),
    );
  }

  Widget _sideButton({
    required IconData icon,
    required String label,
    required String semantics,
    required VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: CameraPalette.forest),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CameraPalette.forest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const inset = 12.0, len = 22.0;
    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * len, y), p);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * len), p);
    }

    corner(inset, inset, 1, 1);
    corner(size.width - inset, inset, -1, 1);
    corner(inset, size.height - inset, 1, -1);
    corner(size.width - inset, size.height - inset, -1, -1);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
