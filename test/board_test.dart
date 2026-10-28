import 'package:athens_transit/core/board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A phone at (lat, lon) every 15 s moving ~10 m/s north; positions in degrees.
  List<Fix> track(int n, {double dLat = 0.0014}) => [for (var i = 0; i < n; i++) (t: i * 15, at: (37.98 + i * dLat, 23.73))];

  test('a bus that stays with the phone for a minute while it moves is the one you are on', () {
    final me = track(5);
    final bus = [for (final f in me) (t: f.t, at: (f.at.$1 + 0.0001, f.at.$2))]; // ~11 m off
    final other = [for (final f in me) (t: f.t, at: (f.at.$1, f.at.$2 + 0.003))]; // ~260 m off
    expect(boardedOn(me, {'040|1': bus, '550|2': other}), '040|1');
  });

  test('standing at a stop next to a bus is not riding it', () {
    final me = [for (var i = 0; i < 5; i++) (t: i * 15, at: (37.98, 23.73))];
    expect(boardedOn(me, {'040|1': me}), isNull);
  });

  test('too short a track, or a bus that leaves you, is nothing', () {
    final me = track(3);
    expect(boardedOn(me, {'040|1': me}), isNull); // 30 s only
    final long = track(6);
    final away = [for (final (i, f) in long.indexed) (t: f.t, at: (f.at.$1 + (i > 3 ? 0.002 : 0), f.at.$2))];
    expect(boardedOn(long, {'040|1': away}), isNull);
  });

  test('two buses together: the closer one', () {
    final me = track(5);
    final a = [for (final f in me) (t: f.t, at: (f.at.$1 + 0.0002, f.at.$2))];
    final b = [for (final f in me) (t: f.t, at: (f.at.$1 + 0.00005, f.at.$2))];
    expect(boardedOn(me, {'a': a, 'b': b}), 'b');
  });
}
