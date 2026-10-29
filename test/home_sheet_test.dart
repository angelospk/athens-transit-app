import 'package:athens_transit/core/geo.dart';
import 'package:athens_transit/core/home_sheet.dart';
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/near_home.dart';
import 'package:flutter_test/flutter_test.dart';

NearPlace place(String name, NearKind kind, double m, List<String> lines) =>
    NearPlace(kind: kind, name: name, lat: 37.98, lon: 23.73, distM: m, lines: lines);

// 2026-11-02 is a Monday; Athens is UTC+2 in November.
DateTime athens(int day, int hour) => DateTime.utc(2026, 11, day, hour - 2);

void main() {
  group('homeGroups', () {
    test('first the nearest bus stop with my lines, then the nearest rail station, then the rest by distance', () {
      final near = [
        place('Α', NearKind.bus, 50, ['550']),
        place('ΣΥΝΤΑΓΜΑ', NearKind.metro, 120, ['M2']),
        place('Β', NearKind.bus, 200, ['040', '550']),
        place('Γ', NearKind.bus, 300, ['040']),
        place('ΣΤΑΘΜΟΣ', NearKind.rail, 400, ['A1']),
      ];
      expect(homeGroups(near, ['040']).map((p) => p.name), ['Β', 'ΣΥΝΤΑΓΜΑ', 'Α', 'Γ', 'ΣΤΑΘΜΟΣ']);
    });

    test('without my lines there: the nearest bus stop', () {
      final near = [
        place('ΣΥΝΤΑΓΜΑ', NearKind.metro, 20, ['M2']),
        place('Α', NearKind.bus, 50, ['550']),
        place('Β', NearKind.bus, 90, ['230']),
      ];
      expect(homeGroups(near, ['040']).map((p) => p.name), ['Α', 'ΣΥΝΤΑΓΜΑ', 'Β']);
    });

    test('a bus stop and a station of one name stay two groups', () {
      final near = [place('ΣΥΝΤΑΓΜΑ', NearKind.bus, 30, ['040']), place('ΣΥΝΤΑΓΜΑ', NearKind.metro, 60, ['M2'])];
      expect(homeGroups(near, const []).map((p) => p.kind), [NearKind.bus, NearKind.metro]);
    });

    test('a tram stop counts as a rail station', () {
      final near = [place('Α', NearKind.bus, 30, ['040']), place('Β', NearKind.bus, 40, ['550']), place('ΤΡΑΜ', NearKind.tram, 300, ['T6'])];
      expect(homeGroups(near, const []).map((p) => p.name), ['Α', 'ΤΡΑΜ', 'Β']);
    });

    test('nothing near: nothing', () => expect(homeGroups(const [], ['040']), isEmpty));

    test('three stops close by do not hide the stop of my line or the station further away', () {
      Pt north(double m) => (37.98 + m / 111195, 23.73);
      final ix = TripIndex(v: 't', s: [
        for (final (n, m) in [('Α', 100.0), ('Β', 200.0), ('Γ', 300.0), ('Δ', 900.0)]) (n, north(m).$1, north(m).$2),
      ], l: {
        '550': {'v': [0, 1, 2]},
        '040': {'v': [3]},
      });
      final st = Station(name: 'ΜΕΤΡΟ', lat: north(1000).$1, lon: north(1000).$2, lines: const ['M2']);
      final got = homeGroups(NearMemo().places(ix, [st], (37.98, 23.73)), ['040']);
      expect(got.take(3).map((p) => p.name), ['Δ', 'ΜΕΤΡΟ', 'Α']);
      expect(got.length, lessThanOrEqualTo(8));
    });

    test('a hundred stops close by do not hide the stop of my line either', () {
      Pt north(double m) => (37.98 + m / 111195, 23.73);
      final ix = TripIndex(v: 't', s: [
        for (var i = 0; i < 100; i++) ('S$i', north(5.0 + i * 8).$1, north(5.0 + i * 8).$2),
        ('ΜΟΥ', north(1500).$1, north(1500).$2),
      ], l: {
        '550': {'v': [for (var i = 0; i < 100; i++) i]},
        '040': {'v': [100]},
      });
      expect(homeGroups(NearMemo().places(ix, const [], (37.98, 23.73)), ['040']).first.name, 'ΜΟΥ');
    });
  });

  test('the kind of a stop in words', () {
    expect(kindLabel(NearKind.bus), 'στάση λεωφορείων');
    expect(kindLabel(NearKind.metro), 'σταθμός μετρό');
    expect(kindLabel(NearKind.tram), 'στάση τραμ');
    expect(kindLabel(NearKind.rail), 'σταθμός προαστιακού');
  });

  test('the walk button opens Google Maps walking directions to the stop', () {
    expect(walkUri(37.975, 23.735).toString(), 'google.navigation:q=37.975,23.735&mode=w');
    expect(walkWebUri(37.975, 23.735).toString(), 'https://www.google.com/maps/dir/?api=1&destination=37.975,23.735&travelmode=walking');
  });

  group('pickSmart', () {
    const home = (37.968, 23.744);
    const work = (38.0, 23.8);
    const away = (37.9, 23.6);
    test('a weekday morning at home with a «Δουλειά»: to work', () {
      expect(pickSmart(utc: athens(2, 8), me: home, home: home, work: work, hasFav: true), Smart.toWork);
    });
    test('the same morning without «Δουλειά»: the next favourite line', () {
      expect(pickSmart(utc: athens(2, 8), me: home, home: home, work: null, hasFav: true), Smart.nextFav);
    });
    test('at home after 10:00, or on Saturday: not to work', () {
      expect(pickSmart(utc: athens(2, 10), me: home, home: home, work: work, hasFav: true), Smart.nextFav);
      expect(pickSmart(utc: athens(7, 8), me: home, home: home, work: work, hasFav: false), Smart.none);
      expect(pickSmart(utc: athens(2, 5), me: home, home: home, work: work, hasFav: false), Smart.none);
    });
    test('away from home: home', () {
      expect(pickSmart(utc: athens(2, 8), me: away, home: home, work: work, hasFav: true), Smart.goHome);
      expect(pickSmart(utc: athens(2, 22), me: away, home: home, work: null, hasFav: false), Smart.goHome);
    });
    test('no «Σπίτι»: the next favourite line, or a question for it', () {
      expect(pickSmart(utc: athens(2, 8), me: away, home: null, work: null, hasFav: true), Smart.nextFav);
      expect(pickSmart(utc: athens(2, 8), me: away, home: null, work: null, hasFav: false), Smart.askHome);
    });
    test('no position: the next favourite line', () {
      expect(pickSmart(utc: athens(2, 8), me: null, home: home, work: work, hasFav: true), Smart.nextFav);
      expect(pickSmart(utc: athens(2, 8), me: null, home: home, work: work, hasFav: false), Smart.none);
    });
  });
}
