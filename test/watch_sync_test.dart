// The favourites the phone sends to the watch apps (docs/WATCH.md): stop ids from the index, no places.

import 'dart:convert';

import 'package:athens_transit/background/watch_sync.dart';
import 'package:athens_transit/core/city.dart';
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/data/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const idx = TripIndex(
    v: 't',
    s: [('ΠΑΠΑΣΠΥΡΟΥ', 37.9551, 23.71535), ('ΣΥΝΤΑΓΜΑ', 37.9755, 23.7348), ('ΣΥΝΤΑΓΜΑ', 37.9760, 23.7352), ('ΧΩΡΙΣ ID', 37.9, 23.7)],
    l: {},
    ids: ['340098', '1001', '1002', ''],
  );

  test('a favourite gets the id of the stop with its name nearby, the nearest one', () {
    expect(stopIdOf(const FavStop(name: 'ΠΑΠΑΣΠΥΡΟΥ', lat: 37.9552, lon: 23.7154), idx), '340098');
    expect(stopIdOf(const FavStop(name: 'ΣΥΝΤΑΓΜΑ', lat: 37.9761, lon: 23.7352), idx), '1002');
    expect(stopIdOf(const FavStop(name: 'ΣΥΝΤΑΓΜΑ', lat: 38.1, lon: 23.9), idx), isNull, reason: 'same name, far away');
    expect(stopIdOf(const FavStop(name: 'ΧΩΡΙΣ ID', lat: 37.9, lon: 23.7), idx), isNull, reason: 'no id in the index');
  });

  test('the payload has the version, the city and the stops, never the place', () {
    final j = jsonDecode(watchPayload(City.thessaloniki, const [
      FavStop(name: 'ΠΑΠΑΣΠΥΡΟΥ', lat: 37.9552, lon: 23.7154, place: Place.home, lines: ['040']),
      FavStop(name: 'ΑΓΝΩΣΤΗ', lat: 37.0, lon: 23.0),
    ], idx)) as Map<String, dynamic>;
    expect(j, {
      'v': 1,
      'city': 'thessaloniki',
      'favs': [
        {'id': '340098', 'name': 'ΠΑΠΑΣΠΥΡΟΥ', 'lines': ['040']},
      ],
    });
    expect(jsonEncode(j), isNot(contains('home')));
    expect(jsonEncode(j), isNot(contains('37.95')), reason: 'no coordinates');
  });

  test('at most 20 stops', () {
    final many = [for (var i = 0; i < 30; i++) const FavStop(name: 'ΠΑΠΑΣΠΥΡΟΥ', lat: 37.9552, lon: 23.7154)];
    final j = jsonDecode(watchPayload(City.athens, many, idx)) as Map<String, dynamic>;
    expect((j['favs'] as List).length, watchMaxFavs);
  });
}
