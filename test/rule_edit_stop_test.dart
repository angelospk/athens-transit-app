// A rule made from the alert sheet at a stop the user never saved: the editor showed «στο —» and
// could not save (QA). It must show the rule's stop and save the rule's changes.
import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/core/rules.dart';
import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/rule_edit.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a rule at a stop that is not saved shows that stop and can be saved', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = MockClient((r) async => http.Response(
        jsonEncode({
          'id': '608',
          'variants': {
            'v1': {'headsign': 'ΓΑΛΑΤΣΙ - ΑΚΑΔΗΜΙΑ - ΝΕΚΡ. ΖΩΓΡΑΦΟΥ', 'direction': 0, 'shape': [[38.0, 23.7], [38.01, 23.7]], 'stops': ['a', 'b', 'c']},
          },
          'stops': {
            'a': {'name': 'ΓΑΛΑΤΣΙ', 'lat': 38.0, 'lon': 23.7},
            'b': {'name': 'ΑΚΑΔΗΜΙΑ', 'lat': 38.005, 'lon': 23.7},
            'c': {'name': 'ΖΩΓΡΑΦΟΥ', 'lat': 38.01, 'lon': 23.7},
          },
        }),
        200,
        headers: {'content-type': 'application/json'}));
    final api = Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    final store = AppStore(prefs);
    const rule = Rule(id: '1', line: '608', variant: 'v1', stopIndex: 1, stopId: 'b', stopName: 'ΑΚΑΔΗΜΙΑ', mode: AlertMode.minutes, n: 5, days: 31, startMin: 295, endMin: 340);
    store.putRule(rule);
    await t.pumpWidget(Deps(
      store: store,
      live: LiveHub(api),
      api: api,
      child: MaterialApp(theme: buildTheme(Brightness.dark), home: const RuleEditScreen(rule: rule)),
    ));
    for (var i = 0; i < 10; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await t.pump();
    }
    expect(find.text(titleCase('ΑΚΑΔΗΜΙΑ')), findsOneWidget);
    final save = t.widget<TextButton>(find.widgetWithText(TextButton, 'Αποθήκευση'));
    expect(save.onPressed, isNotNull);
  });
}
