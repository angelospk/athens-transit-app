// Other cities (app#18): Thessaloniki first. Each city has its own backend, static files and stop index
// (the web's cities.ts / cityBases.ts). Athens keeps everything it had: its URLs, its cache files and the
// top level of the saved state, which the alert service and the home widget read (they stay Athens only).
import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/core/city.dart';
import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _stop = FavStop(name: 'ΣΥΝΤΑΓΜΑ', lat: 37.975, lon: 23.735, lines: ['040']);
const _thessStop = FavStop(name: 'ΚΑΜΑΡΑ', lat: 40.632, lon: 22.951, lines: ['10']);

void main() {
  test('the cities: Athens as before; Thessaloniki on its own backend, buses only', () {
    expect(City.values, [City.athens, City.thessaloniki]);
    expect(City.byId('thessaloniki'), City.thessaloniki);
    expect(City.byId('patra'), City.athens); // a city this version does not know
    expect(City.byId(null), City.athens);

    expect(City.athens.api, apiBase);
    expect(City.athens.static, staticBase);
    expect(City.athens.trips, tripsUrl);
    expect(City.thessaloniki.api, 'https://transit-thess.haroldpoi.dev');
    expect(City.thessaloniki.static, 'https://transit-thess.haroldpoi.dev/static/v1');
    expect(City.thessaloniki.trips, 'https://staseis.gr/trips-thessaloniki.json');

    expect(City.athens.name, 'Αθήνα');
    expect(City.thessaloniki.name, 'Θεσσαλονίκη');
    expect(City.thessaloniki.agency, 'ΟΣΕΘ');
    expect(City.athens.agency, 'ΟΑΣΑ');
    // The map starts at the centre when there is no location.
    expect(City.athens.centre, (37.9755, 23.7348));
    expect(City.thessaloniki.centre.$1, closeTo(40.63, .02));
    expect(City.thessaloniki.centre.$2, closeTo(22.94, .02));

    // The vehicle tiles each backend serves (a tile outside is a 404): the map asks only inside.
    expect(City.athens.box, (s: 37.5, w: 22.9, n: 38.5, e: 24.5));
    expect(City.thessaloniki.box, (s: 40.3, w: 22.6, n: 41.0, e: 23.4));

    // What only Athens has: metro/tram/rail, «Δημοτικά», the planner, stop alerts, the statistics.
    for (final c in City.values) {
      final a = c == City.athens;
      expect([c.rail, c.muni, c.plan, c.alerts, c.stats], [a, a, a, a, a], reason: c.name);
    }
  });

  test('Api asks the city\'s own backend, static files and stop index', () async {
    final asked = <String>[];
    final api = Api(
      city: City.thessaloniki,
      client: MockClient((r) async {
        asked.add(r.url.toString());
        final body = r.url.path.endsWith('/lines.json') ? [] : <String, dynamic>{};
        return http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});
      }),
      cache: DiskCache(dir: Directory.systemTemp.createTempSync()),
    );
    expect(api.city, City.thessaloniki);
    await api.lines();
    await api.lineSchedule('10');
    await api.trips().then((_) {}, onError: (_) {}); // the stop index: only its URL matters here
    expect(asked, [
      'https://transit-thess.haroldpoi.dev/static/v1/lines.json',
      'https://transit-thess.haroldpoi.dev/v1/lines/10/schedule',
      'https://staseis.gr/trips-thessaloniki.json',
    ]);
    expect(Api(client: MockClient((_) async => http.Response('', 500))).city, City.athens);
  });

  test('one disk cache, two cities: a city never reads the other\'s saved files', () async {
    final dir = Directory.systemTemp.createTempSync();
    final asked = <String>[];
    http.Client client() => MockClient((r) async {
          asked.add(r.url.host);
          final id = r.url.host.startsWith('transit-thess') ? 'TH' : 'ATH';
          return http.Response(jsonEncode([{'id': id, 'name': id}]), 200, headers: {'content-type': 'application/json'});
        });
    final th = await Api(city: City.thessaloniki, client: client(), cache: DiskCache(dir: dir)).lines();
    final ath = await Api(client: client(), cache: DiskCache(dir: dir)).lines();
    expect(th.single.id, 'TH');
    expect(ath.single.id, 'ATH');
    // Athens keeps the file names it had: an update does not throw away the saved copies.
    expect(File('${dir.path}/lines.json').existsSync(), isTrue);
  });

  group('the store: each city its own stops and lines; the top level stays Athens', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('a switch to Thessaloniki starts empty; Athens\'s stops stay where the alerts read them', () {
      final store = AppStore(prefs)..addFav(_stop);
      expect(store.city, City.athens);
      store.setCity(City.thessaloniki);
      expect(store.city, City.thessaloniki);
      expect(cityOf(prefs), City.thessaloniki);
      expect(store.favs, isEmpty);
      expect(store.myLines, isEmpty);
      store.addFav(_thessStop);
      store.setOnlyMine(true);
      expect(store.myLines, ['10']);

      final blob = jsonDecode(prefs.getString(stateKey)!) as Map<String, dynamic>;
      expect([for (final f in blob['favs'] as List) f['name']], ['ΣΥΝΤΑΓΜΑ']);
      expect(blob['myLines'], ['040']);
      expect(blob['onlyMine'], false);
      expect([for (final f in blob['cities']['thessaloniki']['favs'] as List) f['name']], ['ΚΑΜΑΡΑ']);

      // The alert service and the widget open the store without a city: Athens.
      final background = AppStore(prefs);
      expect(background.city, City.athens);
      expect(background.favs.single.name, 'ΣΥΝΤΑΓΜΑ');
      // Its saves keep the other cities.
      background.setWalkMin(7);
      final again = AppStore(prefs, city: cityOf(prefs));
      expect(again.city, City.thessaloniki);
      expect(again.favs.single.name, 'ΚΑΜΑΡΑ');
      expect(again.onlyMine, isTrue);
      expect(again.walkMin, 7); // settings are the same in every city

      again.setCity(City.athens);
      expect(again.favs.single.name, 'ΣΥΝΤΑΓΜΑ');
      expect(again.myLines, ['040']);
      expect(again.onlyMine, isFalse);
      expect(cityOf(prefs), City.athens);
    });

    test('«Διαγραφή όλων» forgets every city and goes back to Athens', () async {
      final store = AppStore(prefs)..setCity(City.thessaloniki);
      store.addFav(_thessStop);
      await store.reset();
      expect(store.city, City.athens);
      expect(cityOf(prefs), City.athens);
      store.setCity(City.thessaloniki);
      expect(store.favs, isEmpty);
    });
  });

  test('a location is kept in any city the app knows, not only in Attica (app#21)', () {
    expect(inAnyCity(37.9755, 23.7348), isTrue); // Syntagma
    expect(inAnyCity(40.6401, 22.9444), isTrue); // Thessaloniki, Aristotelous
    expect(inAnyCity(39.6650, 20.8537), isFalse); // Ioannina: no city here
    expect(inAnyCity(37.4219, -122.084), isFalse); // the emulator's default
  });
}
