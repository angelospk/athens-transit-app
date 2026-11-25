import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:athens_transit/core/style_loads.dart';

void main() {
  group('StyleLoads.load', () {
    // Dark mode: the map opens with the dark style URL, then the lightened style (data/basemap.dart)
    // replaces it while the first setup still adds its layers. The new style starts empty, so it
    // needs its own setup; joining the first one left it without lines.
    test('a new style load during a setup gets its own setup, after the first one', () async {
      final s = StyleLoads();
      final gate = Completer<void>();
      final runs = <String>[];
      late bool Function() firstCurrent;
      final a = s.load((current) async {
        firstCurrent = current;
        runs.add('a start');
        await gate.future;
        runs.add('a end');
      });
      await pumpEventQueue(); // the first setup runs
      final b = s.load((current) async => runs.add('b'));
      await pumpEventQueue();
      expect(firstCurrent(), isFalse, reason: 'the first setup stops at its next step');
      gate.complete();
      await Future.wait([a, b]);
      expect(runs, ['a start', 'a end', 'b']);
    });

    test('a failed setup does not block the next load', () async {
      final s = StyleLoads();
      await expectLater(s.load((_) async => throw StateError('sourceAlreadyExists')), throwsStateError);
      var ran = false;
      await s.load((_) async => ran = true);
      expect(ran, isTrue);
    });

    test('a setup that failed while a newer load waited does not stop the newer one', () async {
      final s = StyleLoads();
      final gate = Completer<void>();
      final a = s.load((_) async {
        await gate.future;
        throw StateError('layer source not found');
      });
      await pumpEventQueue();
      var ran = false;
      final b = s.load((current) async => ran = current());
      gate.complete();
      await expectLater(a, throwsStateError);
      await b;
      expect(ran, isTrue);
    });
  });

  test('a load superseded before its setup started skips it', () async {
    final s = StyleLoads();
    final runs = <String>[];
    final a = s.load((_) async => runs.add('a'));
    final b = s.load((_) async => runs.add('b'));
    await Future.wait([a, b]);
    expect(runs, ['b']);
  });

  group('StyleLoads.fill', () {
    test('a failed fill is tried again at the next call; a done one is not', () async {
      final s = StyleLoads();
      await s.load((_) async {});
      var metro = 0, rail = 0;
      var metroFails = true;
      Map<String, Future<void> Function()> fills() => {
            'metro': () async {
              metro++;
              if (metroFails) throw Exception('offline');
            },
            'rail': () async => rail++,
          };
      await s.fill(fills());
      metroFails = false;
      await s.fill(fills());
      await s.fill(fills());
      expect(metro, 2);
      expect(rail, 1);
    });

    test('a fill still running is not started again', () async {
      final s = StyleLoads();
      await s.load((_) async {});
      final gate = Completer<void>();
      var n = 0;
      final f = {
        'metro': () async {
          n++;
          await gate.future;
        }
      };
      final first = s.fill(f);
      await s.fill(f);
      gate.complete();
      await first;
      await s.fill(f);
      expect(n, 1);
    });

    test('a new style needs every fill again', () async {
      final s = StyleLoads();
      await s.load((_) async {});
      var n = 0;
      final f = {'metro': () async => n++};
      await s.fill(f);
      await s.load((_) async {});
      await s.fill(f);
      expect(n, 2);
    });

    test('a fill that ends after a new style load does not count for the new style', () async {
      final s = StyleLoads();
      await s.load((_) async {});
      final gate = Completer<void>();
      var n = 0;
      final first = s.fill({
        'metro': () async {
          n++;
          await gate.future;
        }
      });
      await s.load((_) async {});
      gate.complete();
      await first;
      await s.fill({'metro': () async => n++});
      expect(n, 2);
    });
  });
}
