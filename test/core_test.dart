import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/core/athens_time.dart';
import 'package:athens_transit/core/eta.dart';
import 'package:athens_transit/core/geo.dart';
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/nearby.dart';
import 'package:athens_transit/core/rules.dart';
import 'package:flutter_test/flutter_test.dart';

dynamic fixture(String name) => jsonDecode(File('test/fixtures/$name').readAsStringSync());

// A straight street north from (37.9, 23.7): 0.001° of latitude is ~111.2 m.
const lat0 = 37.9, lon0 = 23.7;
Pt north(double m) => (lat0 + m / 111195, lon0);

LineStatic straightLine() => LineStatic.fromJson({
      'id': 'T1',
      'variants': {
        'v1': {
          'headsign': 'ΒΟΡΡΑΣ',
          'direction': 0,
          'shape': [for (final m in [0.0, 1000.0, 2000.0, 3000.0]) [north(m).$1, north(m).$2]],
          'stops': ['s0', 's1', 's2', 's3'],
        }
      },
      'stops': {
        for (final (id, m) in [('s0', 0.0), ('s1', 1000.0), ('s2', 2000.0), ('s3', 3000.0)])
          id: {'name': 'STOP $id', 'lat': north(m).$1, 'lon': north(m).$2},
      },
    });

Vehicle vehicleAt(double m, {String? next, int at = 1000, List<double?>? speeds, double? speed = 5, int? delay}) =>
    Vehicle.fromJson({
      'id': 'bus$m',
      'lat': north(m).$1,
      'lon': north(m).$2,
      'bearing': 0,
      'position_at': at,
      'variant': 'v1',
      'trip_id': 'trip$m',
      'delay_s': delay,
      'next_stop_id': next,
      'speed': speed,
      'path_speeds': speeds,
    });

void main() {
  group('models', () {
    test('parse /v1/lines/{id} fixture', () {
      final live = LineLive.fromJson(fixture('line-040.json'));
      expect(live.line, '040');
      expect(live.vehicles, hasLength(3));
      final v = live.vehicles.first;
      expect(v.id, '44548');
      expect(v.variant, '5512');
      expect(v.nextStopId, '60810');
      expect(v.delayS, 140);
      expect(v.speed, 6.4);
      expect(live.vehicles[2].nextStopId, isNull);
      expect(live.vehicles[2].pathSpeeds, isNull);
    });

    test('parse static line and lines.json', () {
      final st = LineStatic.fromJson(fixture('lines-040.json'));
      expect(st.variants.keys, containsAll(['5512', '5513', '5535']));
      expect(st.variants['5512']!.stops, hasLength(36));
      expect(st.stops['60810'], isNotNull);
      final lines = parseLines(fixture('lines.json'));
      expect(lines.first.id, isNotEmpty);
      expect(lines.first.name, isNotEmpty);
    });
  });

  group('geo', () {
    test('distance and shape length', () {
      expect(distM(north(0), north(1000)), closeTo(1000, 2));
      expect(shapeLength([north(0), north(1000), north(2500)]), closeTo(2500, 4));
    });

    test('project a point onto a shape', () {
      final shape = [north(0), north(1000), north(2000)];
      final p = (north(1500).$1, lon0 + 0.0003); // ~26 m east of the street
      final r = project(shape, p)!;
      expect(r.s, closeTo(1500, 3));
      expect(r.offM, closeTo(26, 3));
      expect(project(shape, (38.5, 24.5)), isNull, reason: 'farther than maxOffM (150 m) from the shape');
    });
  });

  group('eta', () {
    final st = straightLine();
    final variant = st.variants['v1']!;

    test('stopsLeft ports approaching() of the web app', () {
      final v = vehicleAt(500, next: 's1', at: 1000);
      expect(stopsLeft(variant.stops, 1, v, 1010), 1);
      expect(stopsLeft(variant.stops, 3, v, 1010), 3);
      expect(stopsLeft(variant.stops, 0, v, 1010), isNull, reason: 'passed');
      expect(stopsLeft(variant.stops, 1, v, 1000 + 121), isNull, reason: 'fix older than 120 s');
      expect(stopsLeft(variant.stops, 1, vehicleAt(500, next: null), 1010), isNull);
    });

    test('ETA walks path_speeds in 200 m steps, then a 4.2 m/s fallback', () {
      // 1000 m to s2 (at 2000 m) at 5 m/s = 200 s.
      final v = vehicleAt(1000, next: 's2', at: 1000, speeds: List.filled(8, 5.0));
      expect(etaSeconds(st, v, 2, 1000)!, closeTo(200, 5));
      // Elapsed time since the fix counts: 30 s later, 170 s left.
      expect(etaSeconds(st, v, 2, 1030)!, closeTo(170, 5));
      // 2000 m to s3: 1600 m at 5 m/s (320 s) + 400 m at 4.2 m/s (~95 s).
      expect(etaSeconds(st, v, 3, 1000)!, closeTo(415, 8));
    });

    test('ETA: null step uses the vehicle speed, no speeds at all uses fallback', () {
      final v = vehicleAt(1000, next: 's2', at: 1000, speeds: [null, null, null, null, null], speed: 10);
      expect(etaSeconds(st, v, 2, 1000)!, closeTo(100, 5));
      final w = vehicleAt(1000, next: 's2', at: 1000, speeds: null, speed: null);
      expect(etaSeconds(st, w, 2, 1000)!, closeTo(1000 / 4.2, 6));
      final standing = vehicleAt(1000, next: 's2', at: 1000, speeds: null, speed: 0);
      expect(etaSeconds(st, standing, 2, 1000)!, closeTo(1000 / 4.2, 6), reason: 'speed 0 is not a usable speed');
    });

    test('ETA never negative, null when passed or unknown variant', () {
      final v = vehicleAt(1990, next: 's2', at: 1000, speeds: List.filled(8, 5.0));
      expect(etaSeconds(st, v, 2, 2000), 0);
      expect(etaSeconds(st, vehicleAt(2500, next: 's3'), 2, 1000), isNull);
      final other = Vehicle.fromJson({'id': 'x', 'lat': north(500).$1, 'lon': lon0, 'position_at': 1000, 'variant': 'nope', 'next_stop_id': 's1'});
      expect(etaSeconds(st, other, 2, 1000), isNull);
    });

    test('arrivalsAt lists live vehicles before the stop, soonest first', () {
      final live = LineLive(line: 'T1', updatedAt: 1000, nextUpdateAt: 1030, vehicles: [
        vehicleAt(1500, next: 's2', speeds: List.filled(8, 5.0)),
        vehicleAt(200, next: 's1', speeds: List.filled(8, 5.0), delay: 180),
        vehicleAt(2500, next: 's3', speeds: List.filled(8, 5.0)), // passed s2
      ]);
      final arr = arrivalsAt('s2', {'T1': st}, {'T1': live}, 1000);
      expect(arr.map((a) => a.vehicleId), ['bus1500.0', 'bus200.0']);
      expect(arr.first.line, 'T1');
      expect(arr.first.headsign, 'ΒΟΡΡΑΣ');
      expect(arr.first.stopsLeft, 1);
      expect(arr[1].stopsLeft, 2);
      expect(arr[1].delayS, 180);
      expect(arr.first.etaS, closeTo(100, 5));
    });
  });

  group('nearby', () {
    final ix = TripIndex.fromJson({
      'v': '2026-07-08',
      's': [
        ['ΠΑΝΕΠΙΣΤΗΜΙΟ', 37.9800, 23.7330],
        ['ΠΑΝΕΠΙΣΤΗΜΙΟ', 37.9802, 23.7334], // other side of the street
        ['ΑΚΑΔΗΜΙΑΣ', 37.9810, 23.7340],
        ['ΜΑΚΡΙΑ', 38.1000, 23.9000],
      ],
      'l': {
        '040': {'a': [0, 2], 'b': [2, 1]},
        '550': {'c': [1, 3]},
      },
    });

    test('stops near a point, nearest first, with the lines that stop there', () {
      final got = nearbyStops(ix, (37.9801, 23.7331), radiusM: 500);
      expect(got.map((s) => s.name), ['ΠΑΝΕΠΙΣΤΗΜΙΟ', 'ΑΚΑΔΗΜΙΑΣ'], reason: 'same-name stops within 150 m merge');
      expect(got.first.lines, ['040', '550']);
      expect(got.first.stopIndexes, unorderedEquals([0, 1]));
      expect(got.first.distM, lessThan(30));
    });

    test('linesAt: every line at stops of that name within 200 m', () {
      expect(linesAt(ix, 'ΠΑΝΕΠΙΣΤΗΜΙΟ', 37.9800, 23.7330), ['040', '550']);
      expect(linesAt(ix, 'ΑΚΑΔΗΜΙΑΣ', 37.9800, 23.7330), ['040'], reason: '~135 m away, same name');
      expect(linesAt(ix, 'ΜΑΚΡΙΑ', 37.9800, 23.7330), isEmpty);
    });

    test('fold ignores case, accents and final sigma', () {
      expect(fold('Πανεπιστήμιο'), fold('ΠΑΝΕΠΙΣΤΗΜΙΟ'));
      expect(fold('Λεωφόρος Κηφισίας'), 'λεωφοροσ κηφισιασ');
      expect(fold('Ϊ ΰ'), 'ι υ');
    });

    test('lines serving a stop name are sorted naturally', () {
      expect(sortLines(['550', 'Α1', '040', '224', 'Χ96']), ['040', '224', '550', 'Α1', 'Χ96']);
    });
  });

  group('athens time', () {
    test('EET in winter, EEST in summer, switch on the last Sunday at 01:00 UTC', () {
      expect(athensOffsetHours(DateTime.utc(2026, 1, 15)), 2);
      expect(athensOffsetHours(DateTime.utc(2026, 7, 15)), 3);
      expect(athensOffsetHours(DateTime.utc(2026, 3, 29, 0, 59)), 2);
      expect(athensOffsetHours(DateTime.utc(2026, 3, 29, 1, 0)), 3);
      expect(athensOffsetHours(DateTime.utc(2026, 10, 25, 0, 59)), 3);
      expect(athensOffsetHours(DateTime.utc(2026, 10, 25, 1, 0)), 2);
      final a = athensWall(DateTime.utc(2026, 10, 27, 6, 14));
      expect((a.hour, a.minute, a.weekday), (8, 14, DateTime.tuesday));
    });
  });

  group('rules', () {
    Rule rule({int days = 0x1F, int start = 8 * 60, int end = 8 * 60 + 40, AlertMode mode = AlertMode.minutes, int n = 5}) => Rule(
          id: 'r1',
          line: 'T1',
          variant: 'v1',
          stopIndex: 2,
          stopId: 's2',
          stopName: 'STOP s2',
          mode: mode,
          n: n,
          days: days,
          startMin: start,
          endMin: end,
        );

    test('active on its days and minutes (Athens wall clock)', () {
      final r = rule();
      expect(r.activeAt(DateTime.utc(2026, 10, 27, 6, 10)), isTrue); // Tue 08:10 Athens
      expect(r.activeAt(DateTime.utc(2026, 10, 27, 6, 41)), isFalse); // 08:41
      expect(r.activeAt(DateTime.utc(2026, 10, 25, 7, 10)), isFalse); // Sunday
      expect(rule(days: 0).activeAt(DateTime.utc(2026, 10, 27, 6, 10)), isFalse);
    });

    test('a one-off rule (days 0, until set) is active until it ends', () {
      final r = rule(days: 0).copyWith(untilS: 2000);
      expect(r.activeAt(DateTime.fromMillisecondsSinceEpoch(1990 * 1000, isUtc: true)), isTrue);
      expect(r.activeAt(DateTime.fromMillisecondsSinceEpoch(2001 * 1000, isUtc: true)), isFalse);
    });

    test('json round trip', () {
      final r = rule(mode: AlertMode.stops, n: 3);
      expect(Rule.fromJson(jsonDecode(jsonEncode(r.toJson()))), r);
    });

    test('watcher fires each trip once per rule, by minutes or by stops', () {
      final st = {'T1': straightLine()};
      final live = {
        'T1': LineLive(line: 'T1', updatedAt: 1000, nextUpdateAt: 1030, vehicles: [
          vehicleAt(1200, next: 's2', speeds: List.filled(8, 5.0)), // 800 m = 160 s
          vehicleAt(0, next: 's1', speeds: List.filled(8, 5.0)), // 2000 m = 400 s, 2 stops
        ])
      };
      final w = RuleWatcher();
      final byMin = rule(mode: AlertMode.minutes, n: 5); // ≤ 300 s
      final hits = w.check([byMin], st, live, 1000);
      expect(hits.map((h) => h.vehicleId), ['bus1200.0']);
      expect(hits.first.etaS, closeTo(160, 5));
      expect(w.check([byMin], st, live, 1005), isEmpty, reason: 'same trip, already fired');

      final w2 = RuleWatcher();
      final byStops = rule(mode: AlertMode.stops, n: 2).copyWith(id: 'r2');
      expect(w2.check([byStops], st, live, 1000).map((h) => h.stopsLeft), [1, 2]);

      // Survives a restart through its snapshot.
      final w3 = RuleWatcher.fromJson(jsonDecode(jsonEncode(w.toJson())));
      expect(w3.check([byMin], st, live, 1010), isEmpty);
    });

    test('watcher ignores a fix older than 120 s (it says nothing about now)', () {
      final st = {'T1': straightLine()};
      final live = {
        'T1': LineLive(line: 'T1', updatedAt: 1000, nextUpdateAt: 1030, vehicles: [
          vehicleAt(1900, next: 's2', at: 1000, speeds: List.filled(8, 5.0)),
        ])
      };
      expect(RuleWatcher().check([rule()], st, live, 1000 + 121), isEmpty);
    });

    test('next start of a weekly rule, in UTC', () {
      final r = rule(); // Mon-Fri 08:00 Athens
      // Tue 27 Oct 2026 08:10 Athens (inside): next is Wed 08:00 = 06:00 UTC (EET).
      expect(nextStartUtc(r, DateTime.utc(2026, 10, 27, 6, 10)), DateTime.utc(2026, 10, 28, 6, 0));
      // Fri 30 Oct 09:00 Athens: next is Mon 2 Nov 08:00.
      expect(nextStartUtc(r, DateTime.utc(2026, 10, 30, 7, 0)), DateTime.utc(2026, 11, 2, 6, 0));
      // Summer time: Mon 6 Jul 07:00 Athens -> same day 08:00 = 05:00 UTC.
      expect(nextStartUtc(r, DateTime.utc(2026, 7, 6, 4, 0)), DateTime.utc(2026, 7, 6, 5, 0));
      expect(nextStartUtc(rule(days: 0).copyWith(untilS: 5000), DateTime.utc(2026)), isNull, reason: 'one-off');
      expect(nextStartUtc(r.copyWith(enabled: false), DateTime.utc(2026)), isNull);
    });

    test('hit text matches the web wording', () {
      expect(hitText(const RuleHit(ruleId: 'r', line: '040', vehicleId: 'x', stopsLeft: 1, etaS: 50, delayS: null), 'ΠΑΝΕΠΙΣΤΗΜΙΟ'),
          'Το 040 έρχεται: επόμενη στάση του η ΠΑΝΕΠΙΣΤΗΜΙΟ.');
      expect(hitText(const RuleHit(ruleId: 'r', line: '040', vehicleId: 'x', stopsLeft: 3, etaS: 290, delayS: 200), 'ΑΓΟΡΑ'),
          'Το 040 είναι 3 στάσεις πριν από ΑΓΟΡΑ (καθυστέρηση 3′), σε ~5′.');
    });
  });
}
