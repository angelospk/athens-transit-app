import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/map_sel.dart';
import 'package:athens_transit/ui/station_panel.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump();
  }
}

Future<void> open(WidgetTester t, StationSel sel, http.Client client) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
  await t.pumpWidget(Deps(
    store: AppStore(prefs),
    live: LiveHub(api),
    api: api,
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: StationPanel(sel: sel, ix: null, scroll: ScrollController())),
    ),
  ));
  await settle(t);
}

void main() {
  testWidgets('a suburban station lists its trains: the end of the line, delay, the timetable time', (t) async {
    final at = DateTime.now().toUtc().add(const Duration(minutes: 10));
    final client = MockClient((r) async {
      expect(r.url.host, 'railway.gov.gr');
      return http.Response(
          jsonEncode({
            'departures': [
              {
                'trainNumber': '1200',
                'to': 'Άγιοι Ανάργυροι',
                'scheduledTime': at.toIso8601String(),
                'actualTime': at.add(const Duration(minutes: 5)).toIso8601String(),
                'status': 'delayed',
                'delay': 5,
                'platform': '3',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    // Αθήνα (Λαρίσης), railway.gov.gr id from assets/suburban.json.
    await open(t, const StationSel('Αθήνα', (38.0, 23.72), lines: ['PIRAIR'], railId: '6928c3c150ab5bc72b39d076'), client);
    expect(find.textContaining('προς '), findsOneWidget);
    expect(find.textContaining('επόμενη στάση Άγιοι'), findsNothing);
    expect(find.textContaining('+5′ καθυστέρηση'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // the platform
  });

  testWidgets('a metro station without the backend says so instead of an empty list', (t) async {
    final client = MockClient((r) async => http.Response('{"error":"warming_up"}', 503));
    await open(t, const StationSel('ΣΥΝΤΑΓΜΑ', (37.975, 23.735), lines: ['M2', 'M3']), client);
    expect(find.textContaining('δεν τα δίνει ακόμη'), findsOneWidget);
  });
}
