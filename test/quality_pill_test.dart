// The line card's quality pill (web v0.2.37): «Χθες · αναμονή ~7′ (κανονικά ~4½′)», a tap opens the 7 days.
import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/quality_pill.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle(WidgetTester t, bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump();
  }
}

const _headers = {'content-type': 'application/json; charset=utf-8'};
final _dayRe = RegExp(r'/days/(\d{4}-\d{2}-\d{2})\.json$');

Map<String, dynamic> _hw(String line, int dir, double cv, double wait, double mean) => {
      'line': line, 'dir': dir, 'n': 90, 'mean_headway_s': mean, 'median_headway_s': 450, 'cv_h': cv,
      'wait_min': wait, 'ewt_min': 1, 'off_headway_share': 0.2, 'los': 'D',
    };

Future<void> _pump(WidgetTester t, {String? headsign, List<Map<String, dynamic>>? by}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final client = MockClient((r) async {
    final m = _dayRe.firstMatch(r.url.path);
    if (m != null) {
      return http.Response(jsonEncode({'version': 1, 'date': m[1], 'headways': {'from_h': 7, 'to_h': 21, 'by_line': by ?? [_hw('040', 0, 0.75, 7.0, 540)]}}), 200, headers: _headers);
    }
    if (r.url.path.endsWith('/schedule')) {
      return http.Response(jsonEncode({'directions': [
        {'direction': 0, 'headsign': 'ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ', 'departures': []},
        {'direction': 1, 'headsign': 'ΣΥΝΤΑΓΜΑ - ΠΕΙΡΑΙΑΣ', 'departures': []},
      ]}), 200, headers: _headers);
    }
    return http.Response('', 404);
  });
  final api = Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
  await t.pumpWidget(Deps(
    store: AppStore(prefs),
    live: LiveHub(api),
    api: api,
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: SingleChildScrollView(child: QualityPill(line: '040', headsign: headsign))),
    ),
  ));
}

void main() {
  testWidgets('the pill says the wait of yesterday, the number in the level colour', (t) async {
    await _pump(t, headsign: 'ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ (ΠΡΟΣΩΡΙΝΗ)');
    await settle(t, () => find.textContaining('Χθες', findRichText: true).evaluate().isNotEmpty);
    expect(find.text('Χθες · αναμονή ~7′ (κανονικά ~4½′)', findRichText: true), findsOneWidget);
    // Closed: no chart text.
    expect(find.textContaining('τελευταίες 7 μέρες'), findsNothing);
  });

  testWidgets('a tap opens the detail and loads the 7 days', (t) async {
    await _pump(t, headsign: 'ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ');
    await settle(t, () => find.textContaining('Χθες', findRichText: true).evaluate().isNotEmpty);
    await t.tap(find.text('Χθες · αναμονή ~7′ (κανονικά ~4½′)', findRichText: true));
    await t.pump();
    expect(find.text('Μέση αναμονή στη στάση, τελευταίες 7 μέρες'), findsOneWidget);
    await settle(t, () => find.textContaining('διελεύσεις').evaluate().isNotEmpty && find.text('Φόρτωση…').evaluate().isEmpty);
    expect(find.textContaining('91 διελεύσεις 07–21, κάθε ~9′ κατά μέσο όρο· 2 στις 10 ήρθαν μαζί'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    await t.tap(find.text('Χθες · αναμονή ~7′ (κανονικά ~4½′)', findRichText: true));
    await t.pump();
    expect(find.text('Μέση αναμονή στη στάση, τελευταίες 7 μέρες'), findsNothing);
  });

  Future<void> noPill(WidgetTester t) async {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await t.pump();
    expect(find.textContaining('Χθες', findRichText: true), findsNothing);
    expect(find.textContaining('Προχθές', findRichText: true), findsNothing);
  }

  testWidgets('no direction known (several shown at once): no pill', (t) async {
    await _pump(t, headsign: null);
    await noPill(t);
  });

  testWidgets('no data for the line: no pill', (t) async {
    await _pump(t, headsign: 'ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ', by: [_hw('041', 0, 0.75, 7.0, 540)]);
    await noPill(t);
  });

  testWidgets('the shown direction (Come) has no headways in the day: no pill', (t) async {
    await _pump(t, headsign: 'ΣΥΝΤΑΓΜΑ - ΠΕΙΡΑΙΑΣ');
    await noPill(t);
  });
}
