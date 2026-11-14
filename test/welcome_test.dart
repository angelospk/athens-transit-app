import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder button(String key) => find.descendant(of: find.byKey(ValueKey(key)), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));

Widget app(Widget home) => MaterialApp(theme: buildTheme(Brightness.light), home: home);

void main() {
  test('the welcome shows on a new install only, and once', () async {
    SharedPreferences.setMockInitialValues({});
    var p = await SharedPreferences.getInstance();
    expect(needsWelcome(p), isTrue);
    await markWelcomed(p);
    expect(needsWelcome(p), isFalse);

    // An install from before the welcome: it already has saved state, so it never sees it.
    SharedPreferences.setMockInitialValues({stateKey: '{}'});
    p = await SharedPreferences.getInstance();
    expect(needsWelcome(p), isFalse);
  });

  testWidgets('four cards, then the permissions; each permission asks once, «Ξεκίνα» ends', (t) async {
    var loc = 0, notes = 0, done = 0;
    await t.pumpWidget(app(WelcomeScreen(
      onDone: () => done++,
      askLocation: () async => ++loc > 0,
      askNotifications: () async => ++notes < 0, // refused
    )));
    expect(find.text('Καλώς ήρθες στις Στάσεις'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await t.tap(find.text('Επόμενο'));
      await t.pumpAndSettle();
    }
    expect(find.text('Δύο άδειες'), findsOneWidget);
    expect(find.text('Επόμενο'), findsNothing);
    expect(find.text('Χωρίς λογαριασμό, διαφημίσεις ή tracking'), findsOneWidget);

    await t.tap(button('ask-location'));
    await t.pumpAndSettle();
    await t.ensureVisible(button('ask-notifications'));
    await t.pumpAndSettle();
    await t.tap(button('ask-notifications'));
    await t.pumpAndSettle();
    expect((loc, notes), (1, 1));
    expect(find.text('Δόθηκε'), findsOneWidget); // location only
    expect(done, 0);

    await t.tap(find.text('Ξεκίνα'));
    await t.pumpAndSettle();
    expect(done, 1);
  });

  testWidgets('«Παράλειψη» skips the tour, not the permissions', (t) async {
    var done = 0;
    await t.pumpWidget(app(WelcomeScreen(onDone: () => done++, askLocation: () async => true, askNotifications: () async => true)));
    await t.tap(find.text('Παράλειψη'));
    await t.pumpAndSettle();
    expect(find.text('Δύο άδειες'), findsOneWidget);
    expect(find.text('Παράλειψη'), findsNothing);
    expect(done, 0);
  });
}
