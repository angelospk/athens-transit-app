import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/alert_sheet.dart';
import 'package:athens_transit/ui/stop_screen.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final st = LineStatic.fromJson(jsonDecode(File('test/fixtures/lines-040.json').readAsStringSync()) as Map<String, dynamic>);
  final vid = st.variants.keys.first;
  final sid = st.variants[vid]!.stops[10];
  final info = st.stops[sid]!;

  Future<void> pump(WidgetTester t, {bool leave = false}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = Api(client: MockClient((_) async => http.Response('', 503)), cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    await t.binding.setSurfaceSize(const Size(400, 900));
    await t.pumpWidget(Deps(
      store: AppStore(prefs),
      live: LiveHub(api),
      api: api,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AlertSheet(
                stop: StopRef(name: info.name, lat: info.lat, lon: info.lon, lines: const ['040']), line: '040', variantId: vid, st: st, stopIndex: 10, etaS: 600, leave: leave),
          ),
        ),
      ),
    ));
  }

  testWidgets('the sheet opens on one button; the rest waits under «Περισσότερες επιλογές»', (t) async {
    await pump(t);
    expect(find.text('Ειδοποίησέ με 5′ πριν'), findsOneWidget);
    expect(find.text('Τώρα αυτό σημαίνει'), findsOneWidget); // the preview stays
    expect(find.text('Περισσότερες επιλογές'), findsOneWidget);
    for (final s in ['Πες μου και αν αργεί', 'Κάθε καθημερινή τέτοια ώρα;', 'Για το τελευταίο της ημέρας', 'Στάσεις πριν']) {
      expect(find.text(s), findsNothing, reason: s);
    }
    await t.tap(find.text('Περισσότερες επιλογές'));
    await t.pumpAndSettle();
    for (final s in ['Πες μου και αν αργεί', 'Κάθε καθημερινή τέτοια ώρα;', 'Για το τελευταίο της ημέρας', 'Στάσεις πριν', 'Φύγε εγκαίρως']) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
  });

  testWidgets('«Φύγε εγκαίρως» from a trip opens the sheet on that mode', (t) async {
    await pump(t, leave: true);
    expect(find.text('Χρειάζομαι τη θέση σου'), findsOneWidget);
    expect(find.text('Πες μου πότε να φύγω'), findsOneWidget);
  });
}
