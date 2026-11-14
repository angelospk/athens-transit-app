// The stop card as the web's: its rows come from the backend's stop board (/v1/stops/{id}), with the web's words, and
// none of the app's own estimates (no «Δεν ξεκίνησαν»). Without a board the card falls back to the phone's estimates.
import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/map_sel.dart';
import 'package:athens_transit/ui/stop_screen.dart';
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

// Two stops of one name (the card's stop and its twin), with GTFS ids and the end of line 040's variant.
String _trips() => jsonEncode({
      'v': 't',
      's': [
        ['ΔΗΜΑΡΧΕΙΟ', 37.98, 23.7, '100'],
        ['ΤΕΡΜΑ', 37.99, 23.71, '101'],
      ],
      'l': {
        '040': {'a': [0, 1]},
        '022': {'b': [0, 1]},
      },
      'd': {
        'n': ['Συκιές'],
        'h': {'040': {'a': 0}},
      },
    });

int get _now => DateTime.now().millisecondsSinceEpoch ~/ 1000;

String _board() => jsonEncode({
      'stop': {'id': '100', 'name': 'ΔΗΜΑΡΧΕΙΟ', 'lat': 37.98, 'lon': 23.7, 'code': '000100'},
      'lines': ['040', '022'],
      'arrivals': [
        {'line': '040', 'headsign': 'Ν.Σ - ΣΥΚΙΕΣ', 'variant': 'a', 'vehicle': '44548', 'eta_s': 600, 'at': _now + 600, 'delay_s': 0, 'position_at': _now, 'source': 'live', 'trip_id': 'x', 'stops_away': 3},
        {'line': '040', 'headsign': 'Ν.Σ - ΣΥΚΙΕΣ', 'variant': 'a', 'vehicle': '44549', 'eta_s': 1500, 'at': _now + 1500, 'delay_s': 0, 'position_at': _now, 'source': 'live', 'trip_id': 'y'},
        // A timetable trip with no bus: the card lists buses only.
        {'line': '022', 'headsign': 'ΑΝΩ ΠΟΛΗ', 'variant': 'b', 'vehicle': '', 'eta_s': 300, 'at': _now + 300, 'delay_s': 0, 'position_at': 0, 'source': 'schedule'},
      ],
      'usual': [
        {'line': '022', 'headsign': 'ΑΝΩ ΠΟΛΗ', 'headway_min': 12},
      ],
      'updated_at': _now,
    });

Future<void> _pump(WidgetTester t, {required http.Response Function(http.Request) answer}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = Api(client: MockClient((r) async => answer(r)), cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
  await t.pumpWidget(Deps(
    store: AppStore(prefs),
    live: LiveHub(api),
    api: api,
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: StopPanel(
          stop: const StopRef(name: 'ΔΗΜΑΡΧΕΙΟ', lat: 37.98, lon: 23.7, lines: ['022', '040']),
          scroll: ScrollController(),
        ),
      ),
    ),
  ));
}

http.Response _json(String body, [int status = 200]) => http.Response(body, status, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  tearDown(() => mapSel.value = null);

  testWidgets('the rows are the board\'s, in the web\'s words: no estimates, no «Δεν ξεκίνησαν»', (t) async {
    await _pump(t, answer: (r) => r.url.path.startsWith('/v1/stops/') ? _json(_board()) : _json(_trips()));
    await settle(t, () => find.textContaining('τελ. ενημέρωση').evaluate().isNotEmpty);
    expect(find.text('→ Συκιές'), findsOneWidget); // the variant's end from the stop index
    expect(find.text('10′'), findsOneWidget);
    expect(find.text('μετά 25′'), findsOneWidget);
    expect(find.text('3 στάσεις πριν · στην ώρα του'), findsOneWidget);
    // 022 has no bus: its usual service, not a row from the timetable.
    expect(find.text('Συνήθως περνά κάθε ~12′ τέτοια ώρα'), findsOneWidget);
    expect(find.textContaining('Δεν ξεκίνησαν'), findsNothing);
    expect(find.textContaining('δεν είδα'), findsNothing);
    expect(find.text('Κωδ. στάσης '), findsNothing); // a rich text: the code is in it
    expect(find.textContaining('000100', findRichText: true), findsOneWidget);
  });

  testWidgets('a tap on a row opens that bus', (t) async {
    await _pump(t, answer: (r) => r.url.path.startsWith('/v1/stops/') ? _json(_board()) : _json(_trips()));
    await settle(t, () => find.text('10′').evaluate().isNotEmpty);
    await t.tap(find.text('10′'));
    await t.pump();
    final sel = mapSel.value;
    expect(sel, isA<BusSel>());
    expect((sel as BusSel).vehicleId, '44548');
  });

  testWidgets('no board (the backend answers 503): the card falls back to the phone\'s estimates, with no board words', (t) async {
    await _pump(t, answer: (r) => r.url.path.startsWith('/v1/stops/') ? _json('{}', 503) : r.url.path.endsWith('trips.json') ? _json(_trips()) : _json('{}', 404));
    await settle(t, () => find.textContaining('Κανένα λεωφορείο με GPS').evaluate().isNotEmpty);
    expect(find.textContaining('Κανένα λεωφορείο με GPS'), findsOneWidget);
    expect(find.textContaining('τελ. ενημέρωση'), findsNothing);
  });
}
