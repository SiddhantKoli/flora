import 'package:flutter/material.dart';

import '../../ui/flora_design.dart';

class FirstPlantGuide extends StatefulWidget {
  const FirstPlantGuide({super.key});

  @override
  State<FirstPlantGuide> createState() => _FirstPlantGuideState();
}

class _FirstPlantGuideState extends State<FirstPlantGuide> {
  int step = 0;

  static const details = [
    (
      Icons.photo_camera_outlined,
      'Spot something green.',
      'Take a clear photo in FLORA. Try a leaf or flower close-up if you can.'
    ),
    (
      Icons.auto_awesome_outlined,
      'You choose the name.',
      'Ask for possible matches, choose one yourself, write your own name, or save Unknown.'
    ),
    (
      Icons.book_outlined,
      'Make it your story.',
      'Add a note and find it in your Journal. Photos and notes stay on this phone; a photo goes to Pl@ntNet only when you ask for suggestions.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final item = details[step];
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                  child:
                      Text('YOUR FIRST FIELD NOTE', style: FloraType.caption)),
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Skip')),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              for (var i = 0; i < details.length; i++) ...[
                Expanded(
                    child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                            color: i <= step
                                ? FloraPalette.signal
                                : FloraPalette.line,
                            borderRadius: BorderRadius.circular(4)))),
                if (i != details.length - 1) const SizedBox(width: 7),
              ],
            ]),
            const SizedBox(height: 26),
            Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: FloraPalette.mint,
                    borderRadius: BorderRadius.circular(18)),
                child: Icon(item.$1, size: 36, color: FloraPalette.ink)),
            const SizedBox(height: 24),
            Text(item.$2, style: FloraType.display),
            const SizedBox(height: 14),
            Text(item.$3,
                style: FloraType.body.copyWith(color: FloraPalette.muted)),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              onPressed: step == details.length - 1
                  ? () => Navigator.pop(context, true)
                  : () => setState(() => step++),
              child: Text(
                  step == details.length - 1 ? 'Take my first photo' : 'Next'),
            ),
            if (step > 0)
              Center(
                  child: TextButton(
                      onPressed: () => setState(() => step--),
                      child: const Text('Back'))),
          ]),
    ));
  }
}
