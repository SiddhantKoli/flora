import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flora/features/onboarding/first_plant_guide.dart';

void main() {
  testWidgets('first-plant guide explains capture, naming, and local storage',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: FirstPlantGuide())));
    expect(find.text('Spot something green.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('You choose the name.'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Make it your story.'), findsOneWidget);
    expect(find.text('Take my first photo'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
