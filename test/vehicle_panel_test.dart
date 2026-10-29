import 'dart:io';

import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/vehicle_screen.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Real I/O (the disk cache) between frames: its callbacks run on the next pump.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump();
  }
}

void main() {
  // A bus of a line the app does not poll, opened without a network: the panel must recover by itself
  // when the network is back (it used to stay on "Δεν βρέθηκε το λεωφορείο").
  testWidgets('a bus opened offline shows up once the network is back', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var online = false;
    final client = MockClient((r) async {
      if (!online) throw const SocketException('offline');
      final f = r.url.host == 'transit.haroldpoi.dev' ? 'line-040.json' : 'lines-040.json'; // live : static
      return http.Response(File('test/fixtures/$f').readAsStringSync(), 200, headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final api = Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    await t.pumpWidget(Deps(
      store: AppStore(prefs),
      live: LiveHub(api),
      api: api,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(body: VehiclePanel(line: '040', vehicleId: '44548', scroll: ScrollController())),
      ),
    ));
    await settle(t);
    expect(find.textContaining('χωρίς σύνδεση'), findsOneWidget);

    online = true;
    await t.pump(const Duration(seconds: 15)); // the retry timer, in fake time
    await settle(t);
    expect(find.textContaining('χωρίς σύνδεση'), findsNothing);
    // One default per screen: the two actions, no follow switch; the vehicle number sits folded.
    expect(find.text('Πού κατεβαίνω;'), findsOneWidget);
    expect(find.text('Κλείδωσε στο λεωφορείο'), findsNothing);
    expect(find.text('Λεπτομέρειες'), findsOneWidget);
    expect(find.text('όχημα 44548'), findsNothing);
    await t.tap(find.text('Λεπτομέρειες'));
    await t.pumpAndSettle();
    expect(find.text('όχημα 44548'), findsOneWidget);
  });

  test('the delay reads as words, not as a signed number', () {
    expect(delayWords(30), 'στην ώρα του');
    expect(delayWords(-60), 'στην ώρα του');
    expect(delayWords(20 * 60), 'αργεί 20′');
    expect(delayWords(-3 * 60), 'νωρίτερα 3′');
  });
}
