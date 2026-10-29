import 'package:athens_transit/ui/map_sel.dart';
import 'package:athens_transit/ui/stop_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const stop = StopRef(name: 'ΣΧΟΛΗ', lat: 38, lon: 23.7, lines: ['040']);
  setUp(() => mapSel.value = null);

  test('back walks through what was opened, then closes', () {
    mapSel.value = const StopSel(stop);
    mapSel.value = const BusSel('040', '1', stop: stop);
    mapSel.value = const LineSel('040');
    expect(canMapBack(), isTrue);
    mapBack();
    expect(mapSel.value, isA<BusSel>());
    mapBack();
    expect(mapSel.value, isA<StopSel>());
    expect(canMapBack(), isFalse);
    mapBack();
    expect(mapSel.value, isNull);
  });

  test('a new direction of the same line replaces, it is not a step back', () {
    mapSel.value = const StopSel(stop);
    mapSel.value = const LineSel('040');
    mapSel.value = const LineSel('040', variants: {'a'});
    mapBack();
    expect(mapSel.value, isA<StopSel>());
  });

  test('closing forgets the history', () {
    mapSel.value = const StopSel(stop);
    mapSel.value = const LineSel('040');
    mapSel.value = null;
    mapSel.value = const LineSel('550');
    expect(canMapBack(), isFalse);
  });

  test('a bus opened from a notification goes back to its stop', () {
    mapSel.value = const BusSel('040', '1', stop: stop);
    expect(canMapBack(), isTrue);
    mapBack();
    expect((mapSel.value as StopSel).stop.name, 'ΣΧΟΛΗ');
  });

  test('«Πίσω» is named after the level before; the first level goes back home', () {
    mapSel.value = const StopSel(stop);
    expect(backLabel(), 'Κοντά σου');
    mapSel.value = const LineSel('040');
    expect(backLabel(), 'Σχολη');
    mapSel.value = const BusSel('040', '1');
    expect(backLabel(), 'Γραμμή 040');
  });
}
