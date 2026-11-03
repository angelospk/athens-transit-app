import 'package:athens_transit/core/last_bus.dart';
import 'package:athens_transit/core/rules.dart';
import 'package:flutter_test/flutter_test.dart';

// iOS runs no code at an alarm: the app sets the notifications of the next weeks ahead, and again
// each time it opens.
void main() {
  Rule rule(String id, {int days = 0x1F, int start = 8 * 60}) => Rule(
        id: id,
        line: 'T1',
        variant: 'v1',
        stopIndex: 2,
        stopId: 's2',
        stopName: 'STOP s2',
        mode: AlertMode.minutes,
        n: 5,
        days: days,
        startMin: start,
        endMin: start + 40,
      );

  test('weekly starts in the next 14 days, sorted, one per moment', () {
    final now = DateTime.utc(2026, 11, 2, 7); // Mon 2 Nov 09:00 Athens (EET): today's 08:00 is past
    final s = startsWithin([rule('a'), rule('b'), rule('c', days: 1 << 5, start: 10 * 60)], now);
    // Mon-Fri 08:00 (a and b at the same moment: one entry), 10 of them from Tue 3 Nov to Mon 16 Nov...
    expect(s.first, DateTime.utc(2026, 11, 3, 6));
    // ...and Saturday 10:00 twice.
    expect(s, contains(DateTime.utc(2026, 11, 7, 8)));
    expect(s, contains(DateTime.utc(2026, 11, 14, 8)));
    expect(s.length, 10 + 2);
    expect(s, orderedEquals([...s]..sort()));
    expect(s.every((t) => t.isAfter(now) && t.isBefore(now.add(const Duration(days: 14)))), isTrue);
  });

  test('starts: a one-off, disabled or dayless rule has none; the list is capped', () {
    final now = DateTime.utc(2026, 11, 2, 7);
    expect(startsWithin([rule('x', days: 0), rule('y').copyWith(enabled: false), rule('z').copyWith(untilS: 9999999999)], now), isEmpty);
    expect(startsWithin([rule('a', days: 0x7F)], now, max: 5).length, 5);
  });

  test('the next evening nudges: Friday and Saturday 21:00 Athens', () {
    final n = nextNudgesUtc(DateTime.utc(2026, 11, 2, 7), 4); // Mon 2 Nov
    expect(n, [
      DateTime.utc(2026, 11, 6, 19), // Fri 21:00 EET
      DateTime.utc(2026, 11, 7, 19),
      DateTime.utc(2026, 11, 13, 19),
      DateTime.utc(2026, 11, 14, 19),
    ]);
  });
}
