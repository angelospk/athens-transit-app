import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/core/stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DayStats.fromJson(jsonDecode(File('test/fixtures/stats_day.json').readAsStringSync()) as Map<String, dynamic>);

  test('a day reads the totals and 24 hours', () {
    expect(day.date, '2026-10-26');
    expect(day.vehicles, 1222);
    expect(day.lines, 278);
    expect(day.hours, hasLength(24));
    expect(day.hours[9].vehicles, 1056);
  });

  test('the day speed is pooled: all metres over all seconds', () {
    expect(day.kmh, closeTo(12.94, .01));
  });

  test('slowest and fastest lines need 15 vehicle-hours, and a line is never in both', () {
    final r = ranking(day, 5);
    expect([for (final x in r.slow) x.line], ['2', '4', '214', '230', '035']);
    expect([for (final x in r.fast) x.line], ['Χ93', 'Χ95', '122', 'Χ96', '304']);
    expect(r.slow.first.kmh, closeTo(7.4, .05));
  });

  test('trips that ran out of the measured ones, the worst lines and the unseen ones', () {
    final s = tripShare(day)!;
    expect(s.share, closeTo(.7146, .0001));
    expect(s.run, 10765);
    expect(s.measured, 15064);
    expect(s.expired, isTrue);
    expect([for (final w in s.worst) w.line], ['124', '906', '164', '036', '522']);
    expect(s.worst.first.missed, 28);
    expect(s.worst.first.measured, 34);
    expect(s.unseen, 6);
  });

  test('a day without trips has no share', () {
    final j = jsonDecode(File('test/fixtures/stats_day.json').readAsStringSync()) as Map<String, dynamic>..remove('trips');
    expect(tripShare(DayStats.fromJson(j)), isNull);
  });
}
