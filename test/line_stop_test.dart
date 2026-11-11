import 'package:athens_transit/core/line_stop.dart';
import 'package:athens_transit/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

// One line, two directions: A→B→C (v1) and C→B→A (v2); B has one pole per direction.
LineStatic _line() => LineStatic(id: '040', variants: {
      'v1': const Variant(headsign: 'C', direction: 0, shape: [], stops: ['a1', 'b1', 'c1']),
      'v2': const Variant(headsign: 'A', direction: 1, shape: [], stops: ['c2', 'b2', 'a2']),
    }, stops: {
      'a1': const StopInfo(name: 'A', lat: 37.970, lon: 23.700),
      'b1': const StopInfo(name: 'B', lat: 37.980, lon: 23.700),
      'c1': const StopInfo(name: 'C', lat: 37.990, lon: 23.700),
      'c2': const StopInfo(name: 'C', lat: 37.9901, lon: 23.7001),
      'b2': const StopInfo(name: 'B', lat: 37.9801, lon: 23.7001),
      'a2': const StopInfo(name: 'A', lat: 37.9701, lon: 23.7001),
    });

void main() {
  test('the stop the card came from, when the direction serves it', () {
    expect(lineStopFor(_line(), {'v1'}, fromIds: {'b1'}, pos: (37.970, 23.700)), (id: 'b1', m: null));
  });

  test('another direction: the nearest stop of it to the user', () {
    // From b1 (direction v1), the card turned to v2: b1 is not on it; the user stands by a2.
    expect(lineStopFor(_line(), {'v2'}, fromIds: {'b1'}, pos: (37.9702, 23.7001))?.id, 'a2');
  });

  test('nearest stop within 1.5 km, with the metres', () {
    final r = lineStopFor(_line(), {'v1'}, pos: (37.9805, 23.700));
    expect(r?.id, 'b1');
    expect(r?.m, inInclusiveRange(50, 60));
  });

  test('no stop of the direction within 1.5 km, or no location: none', () {
    expect(lineStopFor(_line(), {'v1'}, pos: (38.10, 23.70)), isNull);
    expect(lineStopFor(_line(), {'v1'}), isNull);
    expect(lineStopFor(_line(), {'nope'}, pos: (37.98, 23.70)), isNull);
  });

  test('the walking directions open the platform map app', () {
    expect(walkUrl(37.98, 23.7, ios: true).toString(), 'https://maps.apple.com/?daddr=37.98,23.7&dirflg=w');
    expect(walkUrl(37.98, 23.7, ios: false).toString(), 'https://www.google.com/maps/dir/?api=1&destination=37.98,23.7&travelmode=walking');
  });
}
