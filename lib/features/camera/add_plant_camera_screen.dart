import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'atomic_purple_camera_skin.dart';
import 'camera_look.dart';
import 'look_baker.dart';

class CameraPalette {
  static const forest = Color(0xFF211629);
  static const forestSoft = Color(0xFF281936);
  static const lime = Color(0xFFD6F451);
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
        setState(() =>
            _errorMessage = 'The camera couldn’t start. Please try again.');
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
        return 'FLORA needs camera access to add a plant photo. Allow it in your phone’s Settings, then try again.';
      default:
        return 'The camera couldn’t start. Please try again.';
    }
  }

  void _setLook(CameraLook look) {
    if (look.id == _look.id) return;
    HapticFeedback.selectionClick();
    setState(() => _look = look);
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

  @override
  Widget build(BuildContext context) => AtomicPurpleCameraSkin(
        preview: _previewLayer(),
        ready: _controller?.value.isInitialized == true && !_busy,
        busy: _busy,
        lookName: _look.name,
        onCapture: _capture,
        onFlip: _flipCamera,
        onBack: () => Navigator.maybePop(context),
        onSettings: _showLookSelector,
        onSkins: _showSkinInfo,
      );

  Future<void> _flipCamera() async {
    if (_busy || _starting) return;
    final old = _controller;
    if (old == null) return;
    _starting = true;
    try {
      final cameras = await availableCameras();
      final direction =
          old.description.lensDirection == CameraLensDirection.back
              ? CameraLensDirection.front
              : CameraLensDirection.back;
      CameraDescription? target;
      for (final camera in cameras) {
        if (camera.lensDirection == direction) {
          target = camera;
          break;
        }
      }
      if (target == null) {
        _snack('No other camera is available.');
        return;
      }
      if (!mounted) return;
      setState(() => _controller = null);
      await old.dispose();
      final next = CameraController(target, ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await next.initialize();
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() {
        _controller = next;
        _errorMessage = null;
      });
      HapticFeedback.selectionClick();
    } on CameraException catch (error) {
      if (mounted) setState(() => _errorMessage = _messageFor(error));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not switch cameras. Try again.');
      }
    } finally {
      _starting = false;
    }
  }

  void _showLookSelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF211629),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .64,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              children: [
                const Text('Photo look',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                const SizedBox(height: 6),
                const Text(
                    'Effects are applied after capture. You can choose the original on review.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFCFB8D9), fontSize: 12)),
                const SizedBox(height: 12),
                ...kCameraLooks.map((look) => ListTile(
                      title: Text(look.name,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(look.traits,
                          style: const TextStyle(color: Color(0xFFCFB8D9))),
                      trailing: _look.id == look.id
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFFD6F451))
                          : null,
                      onTap: () {
                        _setLook(look);
                        Navigator.pop(sheetContext);
                      },
                    )),
              ]),
        ),
      ),
    );
  }

  void _showSkinInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF211629),
      showDragHandle: true,
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.style_rounded, size: 40, color: Color(0xFFD6F451)),
            SizedBox(height: 12),
            Text('Atomic Purple',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            SizedBox(height: 8),
            Text('Current camera style',
                style: TextStyle(color: Color(0xFFD6F451))),
            SizedBox(height: 14),
            Text(
                'Take a photo here to add a plant. FLORA does not identify plants; you choose one on the next screen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFCFB8D9), height: 1.4)),
          ]),
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
}
