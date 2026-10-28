// The long-term statistics, ported from athens-transit-map/tests/stats.test.ts and
// tests/stats-load.test.ts (validDay).
import 'package:athens_transit/core/stats.dart';
import 'package:flutter_test/flutter_test.dart';

// 00:00 and 23:59 on 2026-10-06 in Athens (UTC+3).
final t0 = DateTime.utc(2026, 10, 5, 21).millisecondsSinceEpoch ~/ 1000;
final t24 = t0 + 86399;

Map<String, dynamic> _hour(int h, {int fixes = 10, int vehicles = 0, double distM = 0, double timeS = 0}) =>
    {'h': h, 'fixes': fixes, 'vehicles': vehicles, 'lines': 1, 'dist_m': distM, 'time_s': timeS};

Map<String, dynamic> _line(String id, double speed, double hours) =>
    {'line': id, 'fixes': 1, 'vehicles': 1, 'time_s': hours * 3600, 'dist_m': speed / 3.6 * hours * 3600};

Map<String, dynamic> _file({
  String date = '2026-10-06',
  int fixes = 0,
  int first = 0,
  int last = 0,
  List<Map<String, dynamic>> byLine = const [],
  List<Map<String, dynamic>>? hours,
}) =>
    {
      'version': 1,
      'date': date,
      'tz': 'Europe/Athens',
      'generated_at': 0,
      'first_fix': first,
      'last_fix': last,
      'fixes': fixes,
      'vehicles': 0,
      'lines': byLine.length,
      'by_line': byLine,
      'hours': hours ??
          [for (var h = 0; h < 24; h++) _hour(h, fixes: 10, vehicles: h, distM: h * 100.0, timeS: h == 0 ? 0.0 : 36.0)],
    };

DayStats _day({int fixes = 0, int first = 0, int last = 0, int Function(int)? fixesPerHour}) => DayStats.fromJson(_file(
      fixes: fixes,
      first: first,
      last: last,
      hours: [
        for (var h = 0; h < 24; h++)
          _hour(h, fixes: fixesPerHour == null ? 10 : fixesPerHour(h), vehicles: h, distM: h * 100.0, timeS: h == 0 ? 0.0 : 36.0),
      ],
    ));

DayStats _full({int first = 0, int last = 0, int Function(int)? fixesPerHour}) =>
    _day(fixes: 1, first: first, last: last, fixesPerHour: fixesPerHour);

// Long-term helpers: complete days of known hours and lines.
DayStats _ld(String date, double? Function(int) kmhAt, {int vehicles = 100, List<Map<String, dynamic>> byLine = const []}) =>
    DayStats.fromJson(_file(date: date, fixes: 1, first: t0, last: t24, byLine: byLine, hours: [
      for (var h = 0; h < 24; h++)
        _hour(h, fixes: 10, vehicles: vehicles, distM: (kmhAt(h) ?? 0) * 1000, timeS: kmhAt(h) == null ? 0.0 : 3600.0),
    ]));

void main() {
  group('gaps', () {
    test('names the hours before the first fix and after the last', () {
      expect(gaps(_full(first: t0 + 2 * 3600 + 600, last: t24)), [0, 1]);
      expect(gaps(_full(first: t0, last: t0 + 21 * 3600)), [22, 23]);
      expect(gaps(_day()), hasLength(24));
    });

    test('names the service hours without any fix', () {
      expect(gaps(_full(first: t0, last: t24)), isEmpty);
      // Night hours 1-4 are often empty: not a gap.
      expect(gaps(_full(first: t0, last: t24, fixesPerHour: (h) => h >= 1 && h <= 4 ? 0 : 5)), isEmpty);
      expect(gaps(_full(first: t0, last: t24, fixesPerHour: (h) => h < 12 ? 0 : 5)), [5, 6, 7, 8, 9, 10, 11]);
    });
  });

  group('complete / isWeekend', () {
    test('a day with gaps is not complete', () {
      expect(complete(_ld('2026-10-07', (_) => 10.0)), isTrue);
      expect(complete(_full(first: t0 + 12 * 3600, last: t24)), isFalse);
    });

    test('Saturday and Sunday are the weekend', () {
      expect([for (final d in ['2026-10-09', '2026-10-10', '2026-10-11', '2026-10-12']) isWeekend(d)],
          [false, true, true, false]);
    });
  });

  group('hourBand', () {
    test('pools sums per hour, never a mean of means; min-max of the days', () {
      final a = _ld('2026-10-07', (h) => h == 3 ? null : 10.0);
      // Day b: hour 8 has 3x the time of day a at 20 km/h; pooled = (10*1 + 20*3) / 4 = 17.5.
      final b = DayStats.fromJson(_file(date: '2026-10-08', fixes: 1, first: t0, last: t24, hours: [
        for (var h = 0; h < 24; h++)
          h == 8
              ? _hour(h, vehicles: 100, distM: 3 * 20000.0, timeS: 3 * 3600.0)
              : _hour(h, vehicles: 100, distM: 20000.0, timeS: 3600.0),
      ]));
      final band = hourBand([a, b]);
      expect(band, hasLength(24));
      expect(band[8].kmh, closeTo(17.5, 1e-9));
      expect(band[8].min, 10);
      expect(band[8].max, 20);
      expect(band[8].n, 2);
      expect(band[3].kmh, 20);
      expect(band[3].min, 20);
      expect(band[3].max, 20);
      expect(band[3].n, 1);
      expect(hourBand([])[0], (h: 0, kmh: null, min: null, max: null, n: 0));
    });
  });

  group('byDayType', () {
    test('splits weekdays from the weekend; vehicles a plain mean, speed pooled', () {
      final t = byDayType([
        _ld('2026-10-08', (_) => 10.0, vehicles: 100),
        _ld('2026-10-09', (_) => 20.0, vehicles: 200),
        _ld('2026-10-10', (_) => 30.0, vehicles: 50),
      ]);
      expect(t.weekday.days, 2);
      expect(t.weekend.days, 1);
      expect(t.weekday.hours[9].h, 9);
      expect(t.weekday.hours[9].vehicles, 150);
      expect(t.weekday.hours[9].kmh, closeTo(15, 1e-9));
      expect(t.weekend.hours[9].vehicles, 50);
      expect(t.weekend.hours[9].kmh, closeTo(30, 1e-9));
      expect(t.weekday.kmh, closeTo(15, 1e-9)); // the whole group pooled: sum dist / sum time
      expect(t.weekend.kmh, closeTo(30, 1e-9));
      final empty = byDayType([]);
      expect(empty.weekend.days, 0);
      expect(empty.weekend.kmh, isNull);
      expect(empty.weekend.hours, hasLength(24));
      expect(empty.weekend.hours[0], (h: 0, vehicles: null, kmh: null));
    });
  });

  group('lineTrends', () {
    // Weekdays 07, 08, 09 (Wed-Fri), weekend 10, 11, Monday 12 the latest.
    List<DayStats> days(List<Map<String, dynamic>> latest) => [
          _ld('2026-10-07', (_) => 10.0, byLine: [_line('a', 20, 20), _line('b', 10, 20), _line('c', 15, 20), _line('thin', 10, 20)]),
          _ld('2026-10-08', (_) => 10.0, byLine: [_line('a', 20, 20), _line('b', 20, 60), _line('c', 15, 20)]),
          _ld('2026-10-10', (_) => 10.0, byLine: [_line('a', 99, 20), _line('b', 99, 20), _line('c', 99, 20)]),
          _ld('2026-10-12', (_) => 10.0, byLine: latest),
        ];

    test('compares the latest day with the earlier days of its type, pooled', () {
      final r = lineTrends(days([_line('a', 10, 20), _line('b', 22.5, 20), _line('c', 15, 20), _line('thin', 5, 14)]), 5)!;
      expect(r.date, '2026-10-12');
      expect(r.weekend, isFalse);
      expect(r.baseDays, 2);
      expect(r.eligible, 3);
      // a: 20 -> 10 = -50 %. b: base (10*20 + 20*60) / 80 = 17.5 -> 22.5. c: no change, in neither list.
      expect([for (final x in r.slower) x.line], ['a']);
      expect(r.slower[0].change, closeTo(-0.5, 1e-9));
      expect([for (final x in r.faster) x.line], ['b']);
      expect(r.faster[0].base, closeTo(17.5, 1e-9));
      expect(r.faster[0].kmh, closeTo(22.5, 1e-9));
    });

    test('orders by change and keeps n', () {
      final d = days([_line('a', 18, 20), _line('b', 1, 20), _line('c', 14, 20)]);
      expect([for (final x in lineTrends(d, 2)!.slower) x.line], ['b', 'a']);
      expect([for (final x in lineTrends(d, 1)!.slower) x.line], ['b']);
    });

    test('is null with fewer than 2 earlier days of the same type', () {
      final d = days([]);
      expect(lineTrends(d.take(3).toList(), 5), isNull); // latest Saturday, no earlier weekend day
      expect(lineTrends([d[0], d[3]], 5), isNull);
    });
  });

  group('validDay', () {
    test('rejects a file that is not the day asked for or has broken hours', () {
      final d = _file(date: '2026-10-07', fixes: 24, first: t0, last: t0 + 86399, byLine: [
        {'line': '1', 'fixes': 24, 'vehicles': 1, 'dist_m': 1, 'time_s': 1},
      ], hours: [
        for (var h = 0; h < 24; h++) _hour(h, fixes: 1, vehicles: 1, distM: 1, timeS: 1),
      ]);
      Map<String, dynamic> edit(Map<String, dynamic> f) => Map<String, dynamic>.of(f);
      expect(validDay(d, '2026-10-07'), isTrue);
      expect(validDay(d, '2026-10-08'), isFalse);
      expect(validDay(edit(d)..['version'] = 2, '2026-10-07'), isFalse);
      final short = [for (final h in d['hours'] as List) h as Map<String, dynamic>]..removeAt(0);
      expect(validDay(edit(d)..['hours'] = short, '2026-10-07'), isFalse);
      final moved = [
        for (var i = 0; i < 24; i++)
          if (i == 3) {...(d['hours'] as List)[i] as Map<String, dynamic>, 'h': 4} else (d['hours'] as List)[i] as Map<String, dynamic>,
      ];
      expect(validDay(edit(d)..['hours'] = moved, '2026-10-07'), isFalse);
      final negative = [
        for (var i = 0; i < 24; i++)
          if (i == 3) {...(d['hours'] as List)[i] as Map<String, dynamic>, 'time_s': -1} else (d['hours'] as List)[i] as Map<String, dynamic>,
      ];
      expect(validDay(edit(d)..['hours'] = negative, '2026-10-07'), isFalse);
      expect(validDay(edit(d)..['by_line'] = [{'line': '1', 'dist_m': double.nan}], '2026-10-07'), isFalse);
      expect(validDay(edit(d)..['tz'] = 'Mars/Olympus', '2026-10-07'), isFalse);
    });
  });
}
