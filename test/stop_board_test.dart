// The stop board's rules, ported from the web's tests/stops.test.ts (web src/lib/stops.ts): the same inputs, the same words.
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/stop_board.dart';
import 'package:flutter_test/flutter_test.dart';

const now = 1000000000000; // ms

StopArrival a(String line, String headsign, int inS, String vehicle,
        {int delay = 0, bool live = true, bool trip = true, int? away, int? dist}) =>
    StopArrival(
      line: line,
      headsign: headsign,
      variant: line + headsign,
      vehicle: vehicle,
      at: now ~/ 1000 + inS,
      delayS: delay,
      live: live,
      tripIdKnown: trip,
      stopsAway: away,
      distanceM: dist,
    );

ArrivalTime t(int min, String v, {int late = 0, bool here = false, int? away, bool est = false}) =>
    ArrivalTime(min: min, vehicle: v, late: late, here: here, away: away, est: est);

// A loop line (309Β-like): out along the north side, round at ΑΥΛΑΚΙ, back on the south side.
const loop = TripIndex(v: 't', s: [
  ('ΑΦΕΤΗΡΙΑ', 37.9, 23.9),
  ('1η ΚΟΜΒΟΣ', 37.9005, 23.905),
  ('ΑΥΛΑΚΙ', 37.9, 23.92),
  ('2η ΚΟΜΒΟΣ', 37.9, 23.9052),
  ('ΕΠΟΜΕΝΗ', 37.9005, 23.906),
], l: {
  'L': {'v': [0, 1, 4, 2, 3, 0]},
});

void main() {
  group('arrivalGroups', () {
    test('by line and headsign, soonest first, in minutes from `at`', () {
      final g = arrivalGroups(
          [a('040', 'ΠΕΙΡΑΙΑΣ', 60, '1'), a('10', 'ΧΑΛΑΝΔΡΙ', 30, '2', delay: 400), a('040', 'ΠΕΙΡΑΙΑΣ', 600, '3'), a('040', 'ΣΥΝΤΑΓΜΑ', 900, '4')],
          now + 30000);
      expect(g.map((x) => (x.line, x.headsign)), [('10', 'ΧΑΛΑΝΔΡΙ'), ('040', 'ΠΕΙΡΑΙΑΣ'), ('040', 'ΣΥΝΤΑΓΜΑ')]);
      expect(g[0].times, [t(0, '2', late: 7)]);
      expect(g[1].times, [t(1, '1'), t(10, '3')]);
      expect(g[2].times, [t(15, '4')]);
    });

    test('a bus more than a minute past its time is gone', () {
      final g = arrivalGroups([a('040', 'Π', 0, '1'), a('040', 'Π', 300, '2')], now + 61000);
      expect(g[0].times.map((x) => x.vehicle), ['2']);
      expect(arrivalGroups([a('040', 'Π', 0, '1')], now + 61000), isEmpty);
    });

    test('only buses: a timetable trip with no bus yet is left out', () {
      final sch = a('040', 'Π', 120, '', live: false);
      expect(arrivalGroups([sch, a('040', 'Π', 300, '2')], now)[0].times.map((x) => x.vehicle), ['2']);
      expect(arrivalGroups([sch], now), isEmpty);
    });

    test('rev 8: at the stop (<= 50 m), stops away from 2 on, an estimate without a trip (~, never late)', () {
      final g = arrivalGroups([
        a('040', 'Π', 10, '1', away: 1, dist: 40),
        a('040', 'Π', 200, '2', away: 1, dist: 600),
        a('040', 'Π', 400, '3', away: 4, dist: 1500),
      ], now);
      expect(g[0].times, [t(0, '1', here: true), t(3, '2'), t(7, '3', away: 4)]);
      final est = arrivalGroups([a('040', 'Π', 420, '9', delay: 300, trip: false, away: 2, dist: 900)], now);
      expect(est[0].times, [t(7, '9', away: 2, est: true)]);
    });

    test('an old server without the rev 8 fields: no hint, no estimate mark', () {
      expect(arrivalGroups([a('040', 'Π', 0, '1'), a('040', 'Π', 300, '2', delay: 180)], now)[0].times, [t(0, '1'), t(5, '2', late: 3)]);
    });

    test('at most 3 times a group', () {
      final many = [for (final k in [1, 2, 3, 4]) a('040', 'Π', k * 120, '$k')];
      expect(arrivalGroups(many, now)[0].times.map((x) => x.vehicle), ['1', '2', '3']);
    });
  });

  test('timeText: at the stop, now, minutes; an estimate carries ~', () {
    expect(timeText(t(0, '1', here: true)), 'στη στάση');
    expect(timeText(t(0, '1')), 'τώρα');
    expect(timeText(t(0, '1', est: true)), '~τώρα');
    expect(timeText(t(7, '1')), '7′');
    expect(timeText(t(7, '1', est: true)), '~7′');
  });

  group('arrivalNote', () {
    test('says where the bus is and whether it is on time', () {
      expect(arrivalNote(t(4, 'v')), (text: 'στην ώρα του', tone: NoteTone.ok));
      expect(arrivalNote(t(4, 'v', late: 1)), (text: 'στην ώρα του', tone: NoteTone.ok));
      expect(arrivalNote(t(9, 'v', late: 3, away: 4)), (text: '4 στάσεις πριν · αργεί 3′', tone: NoteTone.late));
      expect(arrivalNote(t(0, 'v', here: true)), (text: 'στη στάση', tone: NoteTone.ok));
    });
    test('estimate, never a delay, for a bus with no trip', () {
      expect(arrivalNote(t(6, 'v', est: true, away: 2)), (text: '2 στάσεις πριν · εκτίμηση', tone: NoteTone.muted));
    });
    test('an early bus is on time', () => expect(arrivalNote(t(6, 'v', late: -3)), (text: 'στην ώρα του', tone: NoteTone.ok)));
  });

  group('toward', () {
    test('the last stop of an end-to-end headsign', () {
      expect(toward('Α. ΠΑΤΗΣΙΑ - Ν. ΠΑΓΚΡΑΤΙ - Ν. ΕΛΒΕΤΙΑ'), 'Ν. ΕΛΒΕΤΙΑ');
      expect(toward('ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ(ΠΡΟΣΩΡΙΝΗ ΛΟΓΩ ΕΡΓΩΝ)'), 'ΣΥΝΤΑΓΜΑ(ΠΡΟΣΩΡΙΝΗ ΛΟΓΩ ΕΡΓΩΝ)');
      expect(toward('ΚΥΚΛΙΚΗ'), 'ΚΥΚΛΙΚΗ');
    });
    test('a dash inside brackets is not a stop', () {
      expect(toward('ΛΑΓΚΑΔΑΣ - ΘΕΣ/ΝΙΚΗ (ΛΑΓΚΑΔΑΣ - ΛΑΓΥΝΑ - ΘΕΣ/ΝΙΚΗ)'), 'ΘΕΣ/ΝΙΚΗ (ΛΑΓΚΑΔΑΣ - ΛΑΓΥΝΑ - ΘΕΣ/ΝΙΚΗ)');
      expect(toward('ΣΥΝΤΑΓΜΑ - ΠΕΙΡΑΙΑΣ (22:00 - 06:00)'), 'ΠΕΙΡΑΙΑΣ (22:00 - 06:00)');
    });
  });

  group('headTo', () {
    test('on a loop, before the turn: the headsign end', () {
      expect(headTo(loop, 'L', 'v', 1, 'ΑΦΕΤΗΡΙΑ - ΑΥΛΑΚΙ'), (to: 'ΑΥΛΑΚΙ', back: false));
    });
    test('on a loop, after the turn: back to the headsign start', () {
      expect(headTo(loop, 'L', 'v', 3, 'ΣΤ. ΚΟΡΩΠΙ - ΑΥΛΑΚΙ'), (to: 'ΣΤ. ΚΟΡΩΠΙ', back: true));
    });
    test('a headsign that names no stop: the turn is the stop farthest from the start', () {
      expect(headTo(loop, 'L', 'v', 3, 'ΚΥΚΛΙΚΗ'), (to: 'ΑΦΕΤΗΡΙΑ', back: true));
      expect(headTo(loop, 'L', 'v', 4, 'ΚΥΚΛΙΚΗ'), (to: 'ΚΥΚΛΙΚΗ', back: false));
    });
    test('a line that ends elsewhere, or an unknown variant: the headsign end', () {
      expect(headTo(loop, 'L', 'nope', 3, 'Χ - Υ'), (to: 'Υ', back: false));
      expect(headTo(loop, 'L', 'v', 2, 'Χ - ΑΥΛΑΚΙ'), (to: 'ΑΥΛΑΚΙ', back: false));
      const near = TripIndex(v: 't', s: [...[('ΑΦΕΤΗΡΙΑ', 37.9, 23.9), ('1η ΚΟΜΒΟΣ', 37.9005, 23.905), ('ΑΥΛΑΚΙ', 37.9, 23.92), ('2η ΚΟΜΒΟΣ', 37.9, 23.9052), ('ΕΠΟΜΕΝΗ', 37.9005, 23.906)], ('ΤΕΡΜΑ', 37.9004, 23.9)], l: {
        'L': {'v': [0, 1, 4, 2, 3, 5]},
      });
      expect(headTo(near, 'L', 'v', 3, 'Χ - ΑΥΛΑΚΙ'), (to: 'ΑΥΛΑΚΙ', back: false));
    });
    test("the variant's end from the index (trips.json d.h) wins over the headsign", () {
      const ix = TripIndex(v: 't', s: [('Α', 0, 0), ('Β', 0, 0.001)], l: {
        '040': {'a': [0, 1]},
      }, dn: ['Τέρμα Χ'], dh: {
        '040': {'a': 0},
      });
      expect(headTo(ix, '040', 'a', 0, 'Χ - Υ'), (to: 'Τέρμα Χ', back: false));
      expect(lineTowardAt(ix, '040', 0), 'Τέρμα Χ');
      expect(lineTowardAt(ix, '040', 1), isNull); // the variant ends there: nobody boards
    });
  });

  group('usualRows (contract rev 18)', () {
    final nowMs = DateTime.utc(2026, 11, 4, 19, 20).millisecondsSinceEpoch; // 21:20 in Athens
    Usual u(String line, {int? headway = 15, int? nextAt}) => Usual(line: line, headsign: 'ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ', headwayMin: headway, nextAt: nextAt);
    final live = ArrivalGroup('040', 'x', 'v')..times.add(t(3, '1'));
    int unix(int h, int m) => DateTime.utc(2026, 11, 4, h, m).millisecondsSinceEpoch ~/ 1000;

    test('a line with no live bus: the headway as text', () {
      expect(usualRows([u('040')], [], nowMs).single.text, 'Συνήθως περνά κάθε ~15′ τέτοια ώρα');
    });
    test('a time when the server has one, in Athens time', () {
      expect(usualRows([u('040', nextAt: unix(19, 40))], [], nowMs).single.text, 'Συνήθως περνά ~21:40 (από τις προηγούμενες εβδομάδες)');
    });
    test('a time already past falls back to the headway, or to nothing', () {
      expect(usualRows([u('040', nextAt: unix(19, 10))], [], nowMs).single.text, 'Συνήθως περνά κάθε ~15′ τέτοια ώρα');
      expect(usualRows([u('040', nextAt: unix(19, 10), headway: null)], [], nowMs), isEmpty);
    });
    test('nothing for a line with a live bus', () {
      expect(usualRows([u('040'), u('608')], [live], nowMs).map((r) => r.line), ['608']);
    });
  });

  test('signCode: the server stop_code in Athens, the stop id elsewhere', () {
    expect(signCode('040054', '40054', athens: true), '040054');
    expect(signCode(null, '40054', athens: true), isNull);
    expect(signCode(null, '1011', athens: false), '1011');
    expect(signCode('', null, athens: false), isNull);
  });

  group('StopBoard.tryParse', () {
    Map<String, Object?> body() => <String, Object?>{
          'stop': {'id': '61000', 'name': 'ΑΚΑΔΗΜΙΑ', 'lat': 37.98, 'lon': 23.73, 'code': '061000'},
          'lines': ['022', '025'],
          'arrivals': <Object?>[
            <String, Object?>{'line': '022', 'headsign': 'Α - Β', 'variant': '3494', 'vehicle': '12170', 'eta_s': 0, 'at': 1794594380, 'delay_s': 389, 'position_at': 1794594089, 'source': 'live', 'trip_id': 'x', 'stops_away': 2, 'distance_m': 100},
            {'line': '025', 'headsign': 'Γ - Δ', 'variant': '1', 'vehicle': '', 'eta_s': 60, 'at': 1794594440, 'delay_s': 0, 'position_at': 0, 'source': 'schedule'},
            {'line': 7}, // not an arrival
          ],
          'usual': [
            {'line': '025', 'headsign': 'Γ - Δ', 'headway_min': 38, 'next_at': 1794595402},
          ],
        };

    test('reads the stop, its lines, live and schedule rows and the usual service', () {
      final b = StopBoard.tryParse(body())!;
      expect([b.id, b.name, b.code], ['61000', 'ΑΚΑΔΗΜΙΑ', '061000']);
      expect(b.lines, ['022', '025']);
      expect(b.arrivals.map((x) => (x.line, x.live, x.stopsAway)), [('022', true, 2), ('025', false, null)]);
      expect(b.usual.single.headwayMin, 38);
    });
    test('an arrival with trip_id null is an estimate; a missing trip_id is not', () {
      final j = body();
      ((j['arrivals'] as List)[0] as Map<String, Object?>)['trip_id'] = null;
      expect(StopBoard.tryParse(j)!.arrivals[0].tripIdKnown, isFalse);
      ((j['arrivals'] as List)[0] as Map).remove('trip_id');
      expect(StopBoard.tryParse(j)!.arrivals[0].tripIdKnown, isTrue);
    });
    test('not a board: null', () {
      expect(StopBoard.tryParse(null), isNull);
      expect(StopBoard.tryParse({'error': 'unknown_stop'}), isNull);
      expect(StopBoard.tryParse({'stop': {'id': '1'}, 'arrivals': 'x'}), isNull);
    });
  });

  test('stopDelay: 2 s while refreshing, at most 3 times, else 20 s', () {
    expect(stopDelay(true, 0), (ms: 2000, quick: 1));
    expect(stopDelay(true, 3), (ms: 20000, quick: 0));
    expect(stopDelay(false, 2), (ms: 20000, quick: 0));
  });
}
