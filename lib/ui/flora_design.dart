import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
