import 'dart:io';

import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/map_sel.dart';
import 'package:athens_transit/ui/menu.dart';
import 'package:athens_transit/ui/settings_screen.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/welcome.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _saved = '{"favs":[{"name":"ΣΥΝΤΑΓΜΑ","lat":37.97,"lon":23.73,"lines":["2"]}],'
    '"places":[{"name":"Σπίτι","label":"Παγκράτι","lat":37.97,"lon":23.75}],"walkMin":7}';

void main() {
  test('reset forgets every saved choice, as on a new install', () async {
    SharedPreferences.setMockInitialValues({stateKey: _saved, welcomeKey: true});
    final p = await SharedPreferences.getInstance();
    final store = AppStore(p);
    expect((store.favs.length, store.places.length, store.walkMin), (1, 1, 7));
    await store.reset();
    expect((store.favs.length, store.places.length, store.walkMin), (0, 0, 4));
    expect(p.getString(stateKey), isNull);
    expect(needsWelcome(p), isTrue);
  });

  testWidgets('«Διαγραφή όλων» asks first, then deletes and opens the welcome', (t) async {
    SharedPreferences.setMockInitialValues({stateKey: _saved, welcomeKey: true});
    final p = await SharedPreferences.getInstance();
    final store = AppStore(p);
    final api = Api(cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    showWelcome.value = false;
    await t.pumpWidget(Deps(
      store: store,
      live: LiveHub(api),
      api: api,
      child: MaterialApp(navigatorKey: navKey, theme: buildTheme(Brightness.light), home: const Scaffold(body: SettingsScreen())),
    ));
    final del = find.text('Διαγραφή όλων των δεδομένων');
    await t.scrollUntilVisible(del, 200);
    await t.tap(del);
    await t.pumpAndSettle();
    await t.tap(find.text('Άκυρο'));
    await t.pumpAndSettle();
    expect(store.favs, isNotEmpty);

    await t.tap(del);
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Διαγραφή'));
    for (var i = 0; i < 100 && !showWelcome.value; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20))); // the disk cache's real I/O
      await t.pump();
    }
    expect(store.favs, isEmpty);
    expect(p.getString(stateKey), isNull);
    expect(showWelcome.value, isTrue);
  });

  testWidgets('«Σχετικά»: the version, the licenses, the terms and the privacy policy', (t) async {
    PackageInfo.setMockInitialValues(appName: 'Στάσεις', packageName: 'gr.staseis.app', version: '0.3.0', buildNumber: '9', buildSignature: '');
    await t.pumpWidget(MaterialApp(theme: buildTheme(Brightness.light), home: const Scaffold(body: AboutScreen())));
    await t.pumpAndSettle();
    expect(find.text('Έκδοση 0.3.0 (9)'), findsOneWidget);
    expect(find.text('Όροι χρήσης'), findsOneWidget);
    expect(find.text('Πολιτική απορρήτου'), findsOneWidget);
    await t.tap(find.text('Άδειες ανοιχτού κώδικα'));
    await t.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
