import 'package:athens_transit/core/eta.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

(Arrival, List<Arrival>) g(String line, int eta) =>
    (Arrival(line: line, variant: 'v', headsign: 'h', vehicleId: line, etaS: eta, stopsLeft: 2, delayS: 0, positionAt: 0), const <Arrival>[]);

void main() {
  final groups = [g('A', 60), g('040', 120), g('B', 180), g('C', 240), g('D', 300), g('E', 360), g('209', 420), g('F', 480), g('G', 540)];

  test('starred lines come first, whatever their minutes; the others by arrival', () {
    final r = stopRows(groups, {'040', '209'});
    expect(r.mine.map((x) => x.$1.line), ['040', '209']);
    expect(r.others.map((x) => x.$1.line), ['A', 'B', 'C', 'D']); // 6 rows in all
    expect(r.hidden, 3);
  });

  test('«Όλες οι γραμμές» shows every row', () {
    final r = stopRows(groups, {'040'}, all: true);
    expect(r.mine.length + r.others.length, groups.length);
    expect(r.hidden, 0);
  });

  test('no starred line: one list, 6 rows', () {
    final r = stopRows(groups, {});
    expect(r.mine, isEmpty);
    expect(r.others.length, 6);
    expect(r.hidden, 3);
  });

  test('many starred lines are all shown, even past 6', () {
    final r = stopRows(groups, {for (final x in groups) x.$1.line});
    expect(r.mine.length, groups.length);
    expect(r.hidden, 0);
  });
}
