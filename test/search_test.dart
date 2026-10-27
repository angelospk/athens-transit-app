import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/search.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('typing a line number lists the line under the field', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = MockClient((r) async {
      if (r.url.path.endsWith('lines.json')) {
        return http.Response(jsonEncode({'lines': [{'id': '040', 'name': 'ΣΥΝΤΑΓΜΑ - ΠΕΙΡΑΙΑΣ'}, {'id': '550', 'name': 'ΚΗΦΙΣΙΑ'}]}), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }
      return http.Response('{"features": []}', 200);
    });
    final api = Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    final store = AppStore(prefs);
    await t.runAsync(() => api.lines());
    await t.pumpWidget(Deps(
      store: store,
      live: LiveHub(api),
      api: api,
      child: MaterialApp(theme: buildTheme(Brightness.light), home: const Scaffold(body: Stack(children: [SafeArea(child: Column(children: [SearchField(ix: null)]))]))),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50))); // the field loads the lines
    await t.pump();
    await t.enterText(find.byType(TextField), '040');
    await t.pump();
    expect(find.text('Συνταγμα - Πειραιας'), findsOneWidget);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500))); // the places timer
    await t.pump();
  });

  testWidgets('a new query drops the places of the old one, also when its request fails', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = MockClient((r) async {
      if (r.url.path.endsWith('lines.json')) return http.Response('{"lines": []}', 200);
      if (r.url.queryParameters['q'] != 'monastiraki') throw const SocketException('offline');
      return http.Response(jsonEncode({'features': [{'properties': {'name': 'Μοναστηράκι'}, 'geometry': {'coordinates': [23.72, 37.97]}}]}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final api = Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    await t.pumpWidget(Deps(
      store: AppStore(prefs),
      live: LiveHub(api),
      api: api,
      child: MaterialApp(theme: buildTheme(Brightness.light), home: const Scaffold(body: SafeArea(child: Column(children: [SearchField(ix: null)])))),
    ));
    Future<void> type(String q) async {
      await t.enterText(find.byType(TextField), q);
      await t.pump(const Duration(milliseconds: 500)); // the debounce timer runs in fake time
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100))); // the request in real time
      await t.pump();
    }

    await type('monastiraki');
    expect(find.text('Μοναστηράκι'), findsOneWidget);
    await type('monastirakia');
    expect(find.text('Μοναστηράκι'), findsNothing);
  });

  test('places are asked with an app User-Agent (Photon refuses the Dart default), once per name', () async {
    String? ua;
    final client = MockClient((r) async {
      ua = r.headers['user-agent'];
      return http.Response(jsonEncode({'features': [
            for (var i = 0; i < 2; i++) {'properties': {'name': 'Μοναστηράκι', 'city': 'Αθήνα'}, 'geometry': {'coordinates': [23.72, 37.97]}}, // node and way
          ]}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final api = Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    final ps = await api.places('monastiraki');
    expect(ps.single.name, 'Μοναστηράκι');
    expect(ua, startsWith('athens-transit'));
  });

  test('two shops of a chain with the same name and city stay two places', () async {
    final client = MockClient((r) async => http.Response(
        jsonEncode({'features': [
          {'properties': {'name': 'Lidl', 'city': 'Αθήνα'}, 'geometry': {'coordinates': [23.72, 37.97]}},
          {'properties': {'name': 'Lidl', 'city': 'Αθήνα'}, 'geometry': {'coordinates': [23.75, 37.99]}},
        ]}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'}));
    final api = Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    expect(await api.places('lidl'), hasLength(2));
  });
}
