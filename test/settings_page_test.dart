import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flora/data/app_preferences.dart';
import 'package:flora/data/game_store.dart';
import 'package:flora/features/settings/settings_page.dart';

void main() {
  testWidgets('local data cannot be deleted without confirmation',
      (tester) async {
    var clears = 0;
    const state = GameSnapshot(
      observations: [],
      plants: [],
      unlockedIds: {},
      xp: 0,
      achievements: {},
      dailyProgress: 0,
      weeklyProgress: 0,
      dailyClaimed: false,
      weeklyClaimed: false,
    );
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: Center(
                      child: FilledButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SettingsPage(
                                        state: state,
                                        preferences: const AppPreferences(),
                                        onPreferencesChanged: (_) async {},
                                        onDataChanged: () async {},
                                        onClearData: () async {
                                          clears++;
                                        },
                                      ))),
                          child: const Text('Open settings'))),
                ))));
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete local data'), 250,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Delete local data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete local FLORA data?'), findsOneWidget);
    expect(clears, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(clears, 0);
    await tester.tap(find.text('Delete local data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();
    expect(clears, 1);
  });
}
