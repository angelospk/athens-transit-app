import 'dart:io';

import 'package:athens_transit/core/city.dart';
import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/menu.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppStore> _menu(WidgetTester tester, {City city = City.athens}) async {
  SharedPreferences.setMockInitialValues({});
  final store = AppStore(await SharedPreferences.getInstance(), city: city);
  final api = Api(city: city, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
  await tester.pumpWidget(Deps(
    store: store,
    live: LiveHub(api),
    api: api,
    child: const MaterialApp(home: Scaffold(body: AppMenu())),
  ));
  return store;
}

void main() {
  // Home-screen widgets exist only on Android: on iOS the menu has no «Widgets» page.
  for (final (platform, shown) in [(TargetPlatform.android, true), (TargetPlatform.iOS, false)]) {
    testWidgets('«Widgets» in the menu on ${platform.name}: $shown', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      await _menu(tester);
      expect(find.text('Widgets'), shown ? findsOneWidget : findsNothing);
      expect(find.text('Ρυθμίσεις'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  // Thessaloniki (app#18): buses only, so no planner, OASA notices, stop alerts, statistics or home widgets.
  testWidgets('the menu names the city; Thessaloniki has only what it can show', (tester) async {
    await _menu(tester);
    expect(find.text('Αθήνα'), findsOneWidget);
    for (final x in ['Διαδρομή', 'Ενημερώσεις', 'Ειδοποιήσεις', 'Στατιστικά']) {
      expect(find.text(x), findsOneWidget, reason: x);
    }
    await _menu(tester, city: City.thessaloniki);
    expect(find.text('Θεσσαλονίκη'), findsOneWidget);
    expect(find.text('Γραμμές'), findsOneWidget);
    for (final x in ['Διαδρομή', 'Ενημερώσεις', 'Ειδοποιήσεις', 'Στατιστικά', 'Widgets']) {
      expect(find.text(x), findsNothing, reason: x);
    }
  });

  testWidgets('«Πόλη» picks a city: the store switches to it', (tester) async {
    final store = await _menu(tester);
    await tester.tap(find.text('Πόλη'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Θεσσαλονίκη'));
    await tester.pumpAndSettle();
    expect(store.city, City.thessaloniki);
  });
}
