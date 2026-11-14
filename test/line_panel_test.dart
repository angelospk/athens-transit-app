// The line card as the web's: two directions are a two-segment control (web v0.2.37, 2a4f541).
import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/line_panel.dart';
import 'package:athens_transit/ui/map_sel.dart';
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

/// Line 040 with its two headsigns only (one variant each).
String _twoDirections() {
  final j = jsonDecode(File('test/fixtures/lines-040.json').readAsStringSync()) as Map<String, dynamic>;
  (j['variants'] as Map<String, dynamic>).remove('5535');
  return jsonEncode(j);
}

Future<void> _pump(WidgetTester t, {required String Function(http.Request) body}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final client = MockClient((r) async => http.Response(body(r), 200, headers: {'content-type': 'application/json; charset=utf-8'}));
  final api = Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
  await t.pumpWidget(Deps(
    store: AppStore(prefs),
    live: LiveHub(api),
    api: api,
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: LinePanel(line: '040', scroll: ScrollController())),
    ),
  ));
}

/// The levels of the fixture's buses (contract rev 23): a frequent direction's gap, a sparse one's delay, none.
String _levels() => jsonEncode({
      'line': 'oasa:040',
      'vehicles': [
        {'id': 'oasa:44548', 'quality': {'level': 'much_worse', 'basis': 'headway', 'gap_s': 720, 'usual_headway_s': 300, 'bunched': false, 'early': false}},
        {'id': 'oasa:44537', 'quality': {'level': 'normal', 'basis': 'schedule', 'bunched': false, 'early': false}},
        {'id': 'oasa:44549', 'quality': null},
      ],
      'segments': <Object>[],
      'sources': [{'state': 'ok'}],
    });

String _fixtures(http.Request r) => File('test/fixtures/${r.url.host == 'transit.haroldpoi.dev' ? 'line-040.json' : 'lines-040.json'}').readAsStringSync();

void main() {
  tearDown(() => mapSel.value = null);

  testWidgets('two directions: a two-segment control with each terminus, no swap button', (t) async {
    await _pump(t, body: (r) => r.url.host == 'transit.haroldpoi.dev' ? _fixtures(r) : _twoDirections());
    await settle(t, () => find.byType(SegmentedButton<String>).evaluate().isNotEmpty);
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
    expect(find.byIcon(Icons.swap_vert), findsNothing);
    expect(find.textContaining('προς '), findsNothing);
    // One direction is always picked: the control has exactly one selected segment.
    final seg = t.widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
    expect(seg.segments, hasLength(2));
    expect(seg.selected, hasLength(1));
    // A tap on the other segment keeps that direction on the map.
    final other = seg.segments.firstWhere((s) => !seg.selected.contains(s.value));
    await t.tap(find.byWidgetPredicate((w) => w is Text && w.data == (other.label as Text).data).first);
    await t.pump();
    final sel = mapSel.value;
    expect(sel, isA<LineSel>());
    expect((sel as LineSel).variants, isNotEmpty);
  });

  testWidgets('the vehicle rows say their live level in words, in its colour; a bus without one keeps its delay', (t) async {
    await _pump(t, body: (r) => r.url.path.startsWith('/v2/') ? _levels() : r.url.host == 'transit.haroldpoi.dev' ? _fixtures(r) : _twoDirections());
    await settle(t, () => find.text('12′ μετά').evaluate().isNotEmpty);
    expect(find.text('12′ μετά'), findsOneWidget);
    expect(find.text('στην ώρα'), findsOneWidget);
    final worst = t.widget<Text>(find.text('12′ μετά'));
    expect(worst.style!.color, const Color(0xFFC92A2A)); // much_worse, light theme
    expect(t.widget<Text>(find.text('στην ώρα')).style!.color, const Color(0xFF1A7F37));
    // The delay words («αργεί 2′») are gone from the rows of buses that have a level.
    expect(find.textContaining('αργεί'), findsNothing);
  });

  testWidgets('an older backend (no v2 answer): the rows keep the delay text', (t) async {
    await _pump(t, body: (r) => r.url.path.startsWith('/v2/') ? throw const SocketException('offline') : r.url.host == 'transit.haroldpoi.dev' ? _fixtures(r) : _twoDirections());
    await settle(t, () => find.textContaining('αργεί').evaluate().isNotEmpty);
    expect(find.textContaining('αργεί'), findsOneWidget); // 44548: 140 s late
    expect(find.text('12′ μετά'), findsNothing);
  });
}
