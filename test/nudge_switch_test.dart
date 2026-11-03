import 'dart:io';

import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/settings_screen.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The evening nudge is a notification: turning it on asks for the permission first (iOS sets the
// notifications ahead, and they never show without it). Refused: the switch stays off.
void main() {
  setUpAll(AndroidFlutterLocalNotificationsPlugin.registerWith);

  for (final granted in [true, false]) {
    testWidgets('nudge switch on, permission ${granted ? 'granted' : 'refused'}', (t) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter_foreground_task/methods'), (c) async => granted ? 0 : 1);
      SharedPreferences.setMockInitialValues({});
      final store = AppStore(await SharedPreferences.getInstance())..setLastBusNudge(false);
      final api = Api(client: MockClient((_) async => http.Response('', 503)), cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
      await t.binding.setSurfaceSize(const Size(400, 1600));
      await t.pumpWidget(Deps(
        store: store,
        live: LiveHub(api),
        api: api,
        child: MaterialApp(theme: buildTheme(Brightness.light), home: const Scaffold(body: SettingsScreen())),
      ));
      await t.tap(find.text('Παρασκευή και Σάββατο βράδυ: το τελευταίο για το σπίτι'));
      await t.pumpAndSettle();
      expect(store.lastBusNudge, granted);
    });
  }
}
