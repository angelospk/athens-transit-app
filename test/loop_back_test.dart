// A loop line (first stop = last stop, 309Β ΣΤ. ΚΟΡΩΠΙ → ΑΥΛΑΚΙ → ΣΤ. ΚΟΡΩΠΙ) has one headsign for the whole
// run. After the turn the bus runs back to the start: the stop rows say «→ Στ. Κορωπι (επιστροφή)», not
// the headsign again on the other side of the road. As in the web (headTo, v0.2.6).
import 'package:athens_transit/core/eta.dart';
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _stops = {
  's0': StopInfo(name: 'ΑΦΕΤΗΡΙΑ', lat: 37.9, lon: 23.9),
  's1': StopInfo(name: '1η ΚΟΜΒΟΣ', lat: 37.9005, lon: 23.905),
  's4': StopInfo(name: 'ΕΠΟΜΕΝΗ', lat: 37.9005, lon: 23.906),
  's2': StopInfo(name: 'ΑΥΛΑΚΙ', lat: 37.9, lon: 23.92),
  's3': StopInfo(name: '2η ΚΟΜΒΟΣ', lat: 37.9, lon: 23.9052),
};

LineStatic _line(String headsign, List<String> stops) => LineStatic(
      id: 'L',
      variants: {'v': Variant(headsign: headsign, direction: 0, shape: _shape, stops: stops)},
      stops: _stops,
    );

// Out along the north side, round at ΑΥΛΑΚΙ, back along the south side.
const _shape = [(37.9, 23.9), (37.9005, 23.9005), (37.9005, 23.92), (37.9, 23.92), (37.9, 23.9)];
const _loop = ['s0', 's1', 's4', 's2', 's3', 's0'];

void main() {
  test('before the turn of a loop: no way back', () {
    final st = _line('ΣΤ. ΚΟΡΩΠΙ - ΑΥΛΑΚΙ', _loop);
    expect(st.returnsTo('v', 1), isNull);
    expect(st.returnsTo('v', 3), isNull); // the turn itself
  });

  test('after the turn: back to the headsign\'s first place', () {
    expect(_line('ΣΤ. ΚΟΡΩΠΙ - ΜΑΡΚΟΠΟΥΛΟ - ΑΥΛΑΚΙ', _loop).returnsTo('v', 4), 'ΣΤ. ΚΟΡΩΠΙ');
  });

  test('a headsign that names no stop: the turn is the stop farthest from the start, back to the first stop', () {
    final st = _line('ΚΥΚΛΙΚΗ', _loop);
    expect(st.returnsTo('v', 2), isNull);
    expect(st.returnsTo('v', 4), 'ΑΦΕΤΗΡΙΑ');
  });

  test('a headsign that ends at the first stop: the turn is not the first stop', () {
    final st = _line('ΑΦΕΤΗΡΙΑ - ΑΥΛΑΚΙ - ΑΦΕΤΗΡΙΑ', _loop);
    expect(st.returnsTo('v', 1), isNull);
    expect(st.returnsTo('v', 4), 'ΑΦΕΤΗΡΙΑ');
  });

  test('the turn found by a name with other accents and case', () {
    expect(_line('ΣΤ. ΚΟΡΩΠΙ - Αυλάκι', _loop).returnsTo('v', 4), 'ΣΤ. ΚΟΡΩΠΙ');
  });

  test('a line that ends elsewhere, an unknown variant or index: no way back', () {
    expect(_line('Χ - ΑΥΛΑΚΙ', ['s0', 's1', 's2', 's3']).returnsTo('v', 3), isNull);
    expect(_line('Χ - ΑΥΛΑΚΙ', _loop).returnsTo('nope', 4), isNull);
    expect(_line('Χ - ΑΥΛΑΚΙ', _loop).returnsTo('v', 9), isNull);
  });

  test('arrivalsAt carries the way back; the row text says so', () {
    final st = _line('ΣΤ. ΚΟΡΩΠΙ - ΑΥΛΑΚΙ', _loop);
    final live = LineLive.fromJson({
      'line': 'L',
      'updated_at': 1000,
      'next_update_at': 1030,
      'vehicles': [
        {'id': 'b1', 'line': 'L', 'lat': 37.9005, 'lon': 23.915, 'position_at': 1000, 'variant': 'v', 'next_stop_id': 's2'},
      ],
    });
    final after = arrivalsAt('s3', {'L': st}, {'L': live}, 1000);
    expect(after.single.back, 'ΣΤ. ΚΟΡΩΠΙ');
    expect(towards(after.single), 'Στ. Κορωπι (επιστροφή)');
    final out = Arrival(line: 'L', variant: 'v', headsign: 'ΣΤ. ΚΟΡΩΠΙ - ΑΥΛΑΚΙ', vehicleId: 'b2', etaS: 60, stopsLeft: 1, delayS: 0, positionAt: 0);
    expect(out.back, isNull);
    expect(towards(out), 'Στ. Κορωπι - Αυλακι');
  });
}
