// Live quality levels (contract rev 23) as the web v0.2.38: a port of tests/liveQuality.test.ts and tests/held.test.ts.
import 'package:athens_transit/core/geo.dart';
import 'package:athens_transit/core/held.dart';
import 'package:athens_transit/core/live_quality.dart';
import 'package:athens_transit/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleQuality hq({QualityLevel level = QualityLevel.normal, int? gap = 300, bool bunched = false}) =>
    VehicleQuality(level: level, basis: 'headway', gapS: gap, usualHeadwayS: 300, stop: 'oasa:1', bunched: bunched);
VehicleQuality sq({QualityLevel level = QualityLevel.normal, bool early = false}) => VehicleQuality(level: level, basis: 'schedule', early: early);

void main() {
  group('QualityLevel.parse', () {
    test('the API words; anything else is unknown', () {
      expect(['normal', 'worse', 'much_worse', 'unknown', 'new_level', null].map(QualityLevel.parse).toList(),
          [QualityLevel.normal, QualityLevel.worse, QualityLevel.muchWorse, QualityLevel.unknown, QualityLevel.unknown, QualityLevel.unknown]);
    });
  });

  group('vehiclePhrase', () {
    test('no quality object (older backend): null, the caller keeps the delay text', () {
      expect(vehiclePhrase(null, 120), isNull);
    });
    test('headway basis: the gap to the bus ahead, in whole minutes', () {
      expect(vehiclePhrase(hq(gap: 720, level: QualityLevel.muchWorse), 30), (text: '12′ μετά', level: QualityLevel.muchWorse));
      expect(vehiclePhrase(hq(gap: 330), null), (text: '6′ μετά', level: QualityLevel.normal));
    });
    test('headway basis: at least 1′', () => expect(vehiclePhrase(hq(gap: 20), null)?.text, '1′ μετά'));
    test('bunched wins over the gap', () {
      expect(vehiclePhrase(hq(gap: 60, bunched: true, level: QualityLevel.muchWorse), null), (text: 'κολλητά', level: QualityLevel.muchWorse));
    });
    test('schedule basis: the delay with a sign', () {
      expect(vehiclePhrase(sq(level: QualityLevel.worse), 420), (text: '+7′', level: QualityLevel.worse));
      expect(vehiclePhrase(sq(), 75), (text: '+1′', level: QualityLevel.normal));
    });
    test('schedule basis: early', () {
      expect(vehiclePhrase(sq(level: QualityLevel.worse, early: true), -130), (text: 'νωρίτερα 2′', level: QualityLevel.worse));
    });
    test('schedule basis under a minute either way: στην ώρα', () {
      expect(vehiclePhrase(sq(), 25)?.text, 'στην ώρα');
      expect(vehiclePhrase(sq(), -50)?.text, 'στην ώρα');
    });
    test('unknown, or no measure behind the level: a dash', () {
      const dash = (text: '—', level: QualityLevel.unknown);
      expect(vehiclePhrase(hq(level: QualityLevel.unknown, gap: null), 200), dash);
      expect(vehiclePhrase(hq(level: QualityLevel.worse, gap: null), 200), dash);
      expect(vehiclePhrase(sq(), null), dash);
      expect(vehiclePhrase(const VehicleQuality(level: QualityLevel.normal), 200), dash); // no basis
    });
  });

  group('LineQuality', () {
    final body = {
      'vehicles': [
        {'id': 'oasa:52134', 'quality': {'level': 'worse', 'basis': 'headway', 'gap_s': 400, 'bunched': false}},
        {'id': 'oasa:7', 'quality': null},
        {'id': 'oasa:8'},
        {'id': 'oasa:9', 'quality': {'level': 'brand_new'}},
      ],
      'segments': [
        {'pattern': 'oasa:5512', 'from': 'oasa:A', 'to': 'oasa:B', 'level': 'worse', 'ratio': 0.7, 'speed': 3.9, 'usual_speed': 5.3, 'n': 3},
        {'pattern': 'oasa:5512', 'from': 'oasa:B'}, // malformed: dropped
      ],
    };
    test('keys the levels like the map\'s vehicles: native vehicle id', () {
      final q = LineQuality.tryParse(body)!;
      expect(q.levelOf('52134'), QualityLevel.worse);
      expect(q.levelOf('7'), QualityLevel.unknown);
      expect(q.levelOf('8'), QualityLevel.unknown);
      expect(q.levelOf('9'), QualityLevel.unknown);
      expect(q.levelOf('999'), isNull, reason: 'a vehicle the list does not have gets no ring');
      expect(q.segments.single.speed, 3.9);
    });
    test('an older backend has no segments; a wrong shape is not a list', () {
      expect(LineQuality.tryParse({'vehicles': []})!.segments, isEmpty);
      expect(LineQuality.tryParse({'oops': 1}), isNull);
      expect(LineQuality.tryParse(null), isNull);
    });
  });

  group('segmentText', () {
    test('names the stops and the speeds in km/h', () {
      expect(segmentText('Καλλιθέα', 'Φιξ', QualityLevel.worse, 3.9, 5.3), 'Καλλιθέα → Φιξ · πιο αργό: 14 km/h, συνήθως 19');
      expect(segmentText('Α', 'Β', QualityLevel.muchWorse, 1.9, 5), 'Α → Β · πολύ πιο αργό: 7 km/h, συνήθως 18');
    });
    test('without a usual speed, no usual', () => expect(segmentText('Α', 'Β', QualityLevel.worse, 3.9, null), 'Α → Β · πιο αργό: 14 km/h'));
  });

  group('haloFeatures', () {
    // A straight route along a parallel, 3 stops ~1.1 km apart (lat 0, lon 0 / 0.01 / 0.02).
    const lon = {'A': 0.0, 'B': 0.01, 'C': 0.02};
    Variant variant(List<String> stops) {
      final xs = [for (final s in stops) lon[s]!];
      final shape = <Pt>[for (var x = xs.reduce((a, b) => a < b ? a : b); x <= xs.reduce((a, b) => a > b ? a : b) + 1e-9; x += 0.0025) (0.0, double.parse(x.toStringAsFixed(4)))];
      return Variant(headsign: '', direction: 0, shape: xs.first > xs.last ? shape.reversed.toList() : shape, stops: stops);
    }

    LineStatic line(Map<String, List<String>> variants) => LineStatic(
          id: '040',
          variants: {for (final e in variants.entries) e.key: variant(e.value)},
          stops: {
            'A': const StopInfo(name: 'ΚΑΛΛΙΘΕΑ', lat: 0, lon: 0),
            'B': const StopInfo(name: 'ΦΙΞ', lat: 0, lon: 0.01),
            'C': const StopInfo(name: 'ΣΥΝΤΑΓΜΑ', lat: 0, lon: 0.02),
          },
        );
    Segment seg({String pattern = 'oasa:5512', String from = 'oasa:A', String to = 'oasa:B', QualityLevel level = QualityLevel.worse}) =>
        Segment(pattern: pattern, from: from, to: to, level: level, ratio: .7, speed: 3.9, usualSpeed: 5.3, n: 3);
    ({List<Object> features, Map<String, String> tips}) halos(LineStatic st, List<Segment> segs, {Set<String>? only}) =>
        haloFeatures(statics: {'040': st}, only: {'040': only}, segs: {'040': segs}, name: (s) => s);

    test('only worse and much_worse segments get a halo, cut from stop to stop', () {
      final r = halos(line({'5512': ['A', 'B', 'C']}), [seg(), seg(from: 'oasa:B', to: 'oasa:C', level: QualityLevel.normal)]);
      expect(r.features, hasLength(1));
      final f = r.features.single as Map<String, Object>;
      expect((f['properties'] as Map)['level'], 'worse');
      final c = ((f['geometry'] as Map)['coordinates'] as List).cast<List<double>>();
      expect(c.first[0], closeTo(0, 1e-6));
      expect(c.last[0], closeTo(0.01, 1e-4)); // stop offsets are in metres: a few metres of rounding
      expect(r.tips[f['id']], 'ΚΑΛΛΙΘΕΑ → ΦΙΞ · πιο αργό: 14 km/h, συνήθως 19');
    });
    test('much_worse too; unknown never', () {
      final r = halos(line({'5512': ['A', 'B', 'C']}), [seg(level: QualityLevel.muchWorse), seg(from: 'oasa:B', to: 'oasa:C', level: QualityLevel.unknown)]);
      expect([for (final f in r.features) ((f as Map)['properties'] as Map)['level']], ['much_worse']);
    });
    test('a pattern that is not drawn (another direction focused, or unknown) gets none', () {
      final l = line({'5512': ['A', 'B', 'C'], '5513': ['C', 'B', 'A']});
      expect(halos(l, [seg()], only: {'5513'}).features, isEmpty);
      expect(halos(line({'5512': ['A', 'B', 'C']}), [seg(pattern: 'oasa:999')]).features, isEmpty);
    });
    test('stops that do not follow each other in the pattern give no halo', () {
      expect(halos(line({'5512': ['A', 'B', 'C']}), [seg(from: 'oasa:A', to: 'oasa:C')]).features, isEmpty);
    });
    test('the same stop pair of two patterns is drawn once', () {
      final l = line({'5512': ['A', 'B', 'C'], '5535': ['A', 'B']});
      expect(halos(l, [seg(), seg(pattern: 'oasa:5535')]).features, hasLength(1));
    });
    test('a line without a drawn route, or without segments: nothing', () {
      expect(haloFeatures(statics: {}, only: {'040': null}, segs: {'040': [seg()]}, name: (s) => s).features, isEmpty);
      expect(halos(line({'5512': ['A', 'B']}), []).features, isEmpty);
    });
  });

  group('subLine', () {
    final shape = <Pt>[(0.0, 0.0), (0.0, 0.01), (0.0, 0.02)];
    test('cuts the ends inside their legs and keeps the vertices between', () {
      final len = shapeLength(shape);
      final c = subLine(shape, len * .25, len * .75);
      expect(c.length, 3);
      expect(c.first.$2, closeTo(0.005, 1e-6));
      expect(c[1], shape[1]);
      expect(c.last.$2, closeTo(0.015, 1e-6));
    });
    test('an empty or backwards range is nothing', () {
      expect(subLine(shape, 50, 50), isEmpty);
      expect(subLine(shape, 90, 10), isEmpty);
    });
  });

  group('held (web held.ts)', () {
    List<int>? parse(Object? b) => b is Map && b['vehicles'] is List ? (b['vehicles'] as List).cast<int>() : null;
    Map<String, Object?> good(List<int> v) => {'vehicles': v};
    const t0 = 1000000;

    test('isWarmingBody: a /v2 body whose source says warming_up', () {
      expect(isWarmingBody({'sources': [{'id': 'pat', 'state': 'warming_up'}], 'lines': []}), isTrue);
      expect(isWarmingBody({'sources': [{'state': 'ok'}, {'state': 'warming_up'}]}), isTrue);
      expect(isWarmingBody({'sources': [{'state': 'ok'}], 'vehicles': []}), isFalse);
      expect(isWarmingBody({'vehicles': []}), isFalse);
      expect(isWarmingBody(null), isFalse);
      expect(isWarmingBody('warming_up'), isFalse);
      expect(isWarmingBody({'sources': 'warming_up'}), isFalse);
    });

    test('a good answer replaces the list and clears the failed mark; an empty one too (night)', () {
      const old = Held<List<int>>([1, 2], t0, failed: true);
      final h = refreshHeld(old, 200, good([3]), parse, t0 + 20000)!;
      expect([h.value, h.at, h.failed], [[3], t0 + 20000, false]);
      expect(refreshHeld(old, 200, good([]), parse, t0 + 20000)!.value, isEmpty);
    });

    for (final (name, status, body) in <(String, int, Object?)>[
      ('503', 503, {'error': 'warming_up'}),
      ('502 with an HTML page', 502, null),
      ('a timeout / network error (status 0)', 0, null),
      ('200 of another shape', 200, {'oops': 1}),
      ('200 that says warming_up, with an empty list', 200, {'sources': [{'state': 'warming_up'}], 'vehicles': <int>[]}),
      ('200 with no body', 200, null),
    ]) {
      test('$name keeps the last list, marked failed, with its time', () {
        const old = Held<List<int>>([1, 2], t0);
        final h = refreshHeld(old, status, body, parse, t0 + 60000)!;
        expect([h.value, h.at, h.failed], [[1, 2], t0, true]);
      });
    }

    test('the time of the last good answer does not move on repeated failures', () {
      var h = refreshHeld<List<int>>(null, 200, good([1]), parse, t0);
      h = refreshHeld(h, 503, null, parse, t0 + 20000);
      h = refreshHeld(h, 0, null, parse, t0 + 40000);
      expect([h!.value, h.at, h.failed], [[1], t0, true]);
    });

    test('drops the list after heldMaxMs without a good answer (10 min)', () {
      expect(heldMaxMs, 600000);
      const old = Held<List<int>>([1], t0, failed: true);
      expect(refreshHeld(old, 503, null, parse, t0 + heldMaxMs - 1), isNotNull);
      expect(refreshHeld(old, 503, null, parse, t0 + heldMaxMs), isNull);
      expect(refreshHeld(old, 200, good([9]), parse, t0 + 3600000)!.value, [9]); // a good answer after a long outage starts again
      expect(refreshHeld<List<int>>(null, 503, null, parse, t0), isNull);
    });

    test('heldNote: none while the last refresh was good; else the age of the last position', () {
      expect(heldNote(const Held<int>(1, t0), t0 + 400000), isNull);
      expect(heldNote(null, t0), isNull);
      expect(heldNote(const Held<int>(1, t0, failed: true), t0 + 180000), 'Ενημέρωση σε εξέλιξη · τελευταία θέση πριν από 3′');
      expect(heldNote(const Held<int>(1, t0, failed: true), t0 + 40000), 'Ενημέρωση σε εξέλιξη · τελευταία θέση πριν από 40″');
      expect(heldNote(const Held<int>(1, t0, failed: true), t0 - 5000), 'Ενημέρωση σε εξέλιξη · τελευταία θέση πριν από 0″');
    });
  });
}
