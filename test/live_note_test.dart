import 'dart:io';

import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The map's sheet puts the note in a Row beside an Expanded title: offline it left the sheet blank.
  testWidgets('offline note lays out beside an Expanded title', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = Api(client: MockClient((_) async => throw const SocketException('offline')), cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    final live = LiveHub(api);
    await t.runAsync(() async {
      live.watch(['040']);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    expect(live.isOffline, isTrue);
    await t.pumpWidget(Deps(
      store: AppStore(prefs),
      live: live,
      api: api,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const Scaffold(body: Row(children: [Expanded(child: Text('Συνταγμα')), LiveNote()])),
      ),
    ));
    expect(t.takeException(), isNull);
    expect(find.textContaining('Χωρίς σύνδεση'), findsOneWidget);
    live.watch([]);
  });
}
