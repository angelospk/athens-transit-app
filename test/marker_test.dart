import 'package:athens_transit/core/marker.dart';
import 'package:athens_transit/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

Vehicle bus({double? bearing, List<List<double>>? path, int at = 1000, int? delay}) => Vehicle.fromJson({
      'id': '1', 'lat': 37.98, 'lon': 23.72, 'position_at': at, 'bearing': bearing, 'delay_s': delay, 'path': path,
    });

void main() {
  test('colour by delay: the web classes, edges included', () {
    expect(delayHex(null), '#6C757D');
    expect(delayHex(-300), '#1A7F37');
    expect(delayHex(120), '#1A7F37');
    expect(delayHex(121), '#A87C00');
    expect(delayHex(300), '#A87C00');
    expect(delayHex(600), '#D9480F');
    expect(delayHex(601), '#C92A2A');
  });

  test('heading: the bearing first, else the path, else none', () {
    expect(headingOf(bus(bearing: 370), (37.98, 23.72)), 10);
    final east = bus(path: [[37.98, 23.72], [37.98, 23.73]]);
    expect(headingOf(east, (37.98, 23.725)), closeTo(90, .5));
    final north = bus(path: [[37.98, 23.72], [37.99, 23.72]]);
    expect(headingOf(north, (37.99, 23.72)), closeTo(0, .5)); // at the path's end: its last metres
    expect(headingOf(bus(), (37.98, 23.72)), isNull);
  });

  test('filters: recent position (1½′) and on time (5′); no trip is not on time', () {
    expect(keptBy(bus(at: 1000), 1090, fresh: true, onTime: false), isTrue);
    expect(keptBy(bus(at: 1000), 1091, fresh: true, onTime: false), isFalse);
    expect(keptBy(bus(delay: 300), 1000, fresh: false, onTime: true), isTrue);
    expect(keptBy(bus(delay: 301), 1000, fresh: false, onTime: true), isFalse);
    expect(keptBy(bus(), 1000, fresh: false, onTime: true), isFalse);
    expect(keptBy(bus(), 99999, fresh: false, onTime: false), isTrue);
  });
}
