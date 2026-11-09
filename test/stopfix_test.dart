import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/core/geo.dart';
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/nearby.dart';
import 'package:athens_transit/core/stopfix.dart';
import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/stopfix_store.dart';
import 'package:athens_transit/ui/stopfix_bar.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _from = (37.97550, 23.73480);
const _pin = (37.97570, 23.73480); // ~22 m north

void main() {
  test('the report text is the web\'s: a line for people, then the #stopfix line scripts/stopfix.ts reads', () {
    final t = stopReportText(stop: '10175', name: 'ΣΥΝΤΑΓΜΑ', from: _from, at: _pin, device: 'a1b2c3d4e5f6');
    expect(t, 'Λάθος θέση στάσης ΣΥΝΤΑΓΜΑ (10175): 22 μ από τη θέση του χάρτη.\n'
        '#stopfix stop=10175 lat=37.975700 lon=23.734800 from=37.975500,23.734800 dev=a1b2c3d4e5f6');
  });

  test('a pin is sent only between 3 and 80 m from the stop', () {
    expect(fixSendable(2), isFalse);
    expect(fixSendable(3), isTrue);
    expect(fixSendable(80), isTrue);
    expect(fixSendable(81), isFalse);
    expect(streetViewUrl(_pin), 'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=37.975700,23.734800');
  });

  test('the stop\'s GTFS id from trips.json, for the stop at a point', () {
    final ix = TripIndex.fromJson({
      'v': 't',
      's': [
        ['ΣΥΝΤΑΓΜΑ', 37.97550, 23.73480, '10175'],
        ['ΣΥΝΤΑΓΜΑ', 37.97570, 23.73490, '10176'],
      ],
      'l': {},
    });
    expect(ix.ids, ['10175', '10176']);
    expect(stopIdAt(ix, 'ΣΥΝΤΑΓΜΑ', 37.97569, 23.73489), '10176');
    expect(stopIdAt(ix, 'ΣΥΝΤΑΓΜΑ', 37.99, 23.73), isNull);
  });

  test('one random device id, and one report per stop, kept in the phone\'s settings', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    final id = deviceId(p);
    expect(id, matches(RegExp(r'^[a-f0-9]{12}$')));
    expect(deviceId(p), id);
    expect(reported(p, '10175'), isFalse);
    await markReported(p, '10175');
    expect(reported(p, '10175'), isTrue);
  });

  test('feedback: Apps Script answers with a redirect to its reply; only {ok: true} counts', () async {
    Map<String, dynamic>? sent;
    final client = MockClient((r) async {
      if (r.method == 'POST') {
        sent = jsonDecode(r.body) as Map<String, dynamic>;
        return http.Response('', 302, headers: {'location': 'https://script.googleusercontent.com/echo?x=1'});
      }
      return http.Response('{"ok":true}', 200);
    });
    final api = Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    expect(await api.sendFeedback(text: 'abc', version: '0.3.0', page: 'app/stop/1', ua: 'x'), isTrue);
    expect(sent, {'text': 'abc', 'version': '0.3.0', 'page': 'app/stop/1', 'ua': 'x'});

    final no = Api(client: MockClient((r) async => http.Response('{"ok":false}', 200)), cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    expect(await no.sendFeedback(text: 'abc', version: '', page: '', ua: ''), isFalse);
    final down = Api(client: MockClient((r) async => throw const SocketException('offline')), cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    expect(await down.sendFeedback(text: 'abc', version: '', page: '', ua: ''), isFalse);
  });

  testWidgets('the bar: a hint until the pin moves, too far, then send and thanks', (t) async {
    var calls = 0;
    var closed = 0;
    Widget bar(Pt at) => MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: StopFixBar(
              name: 'ΣΥΝΤΑΓΜΑ',
              from: _from,
              at: at,
              send: () async {
                calls++;
                return true;
              },
              onClose: () => closed++,
            ),
          ),
        );
    await t.pumpWidget(bar(_from));
    expect(find.text('Η μικρή τελεία είναι η θέση που ξέρουμε.'), findsOneWidget);
    await t.tap(find.text('Αποστολή'));
    expect(calls, 0); // nothing moved

    await t.pumpWidget(bar((37.9765, 23.7348))); // ~110 m
    expect(find.textContaining('Πάνω από 80 μ'), findsOneWidget);

    await t.pumpWidget(bar(_pin));
    expect(find.text('Μετακίνηση 22 μ.'), findsOneWidget);
    expect(find.text('Δες το σημείο στο Street View ›'), findsOneWidget);
    await t.tap(find.text('Αποστολή'));
    await t.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Ευχαριστούμε, το πήραμε!'), findsOneWidget);
    await t.tap(find.text('Κλείσιμο'));
    expect(closed, 1);
  });
}
