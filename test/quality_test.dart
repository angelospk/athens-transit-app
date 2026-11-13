// The line card's «Χθες» quality pill: a port of the web's src/lib/quality.ts and tests/quality.test.ts (v0.2.37,
// 2a4f541). Only the frequent-direction kind («wait»): the sparse kind reads origin_otp, which only the
// citybus.gr cities have, and the app has none.
import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/core/city.dart';
import 'package:athens_transit/core/quality.dart';
import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> hw(num cvH, {num waitMin = 6.4, num mean = 480, int dir = 0, String line = '040'}) => {
      'line': line, 'dir': dir, 'n': 90, 'mean_headway_s': mean, 'median_headway_s': 450, 'cv_h': cvH,
      'wait_min': waitMin, 'ewt_min': 1, 'off_headway_share': 0.2, 'los': 'D',
    };

QualityDay day(List<Map<String, dynamic>> by, {int? from, int? to}) =>
    QualityDay.fromJson({'headways': {'from_h': ?from, 'to_h': ?to, 'by_line': by}});

String? text(WaitQuality? q) => q == null ? null : '${q.level}|${q.text}';

void main() {
  test('halfMin rounds to the nearest half minute', () {
    expect([4.5, 4.24, 4.26, 7, 6.9, 0.4, 0.2, 10.75].map(halfMin).toList(), ['4½', '4', '4½', '7', '7', '½', '0', '11']);
  });

  group('lineQuality', () {
    test('3 bars at cv_h 0.39, without the usual wait', () {
      expect(text(lineQuality(day([hw(0.39, waitMin: 4.4)]), '040', 0)), '3|αναμονή ~4½′');
    });
    test('2 just above 0.39 and at 0.74, with the usual wait', () {
      for (final cv in [0.391, 0.74]) {
        expect(text(lineQuality(day([hw(cv)]), '040', 0)), '2|αναμονή ~6½′ (κανονικά ~4′)');
      }
    });
    test('1 above 0.74', () {
      expect(text(lineQuality(day([hw(0.75, waitMin: 7.0, mean: 540)]), '040', 0)), '1|αναμονή ~7′ (κανονικά ~4½′)');
    });
    test('the number carries the level colour: parts join to the text', () {
      final q = lineQuality(day([hw(0.75, waitMin: 7.0, mean: 540)]), '040', 0)!;
      expect(q.parts, ['αναμονή ', '~7′', ' (κανονικά ~4½′)']);
      expect(q.parts.join(), q.text);
    });
    test('keeps the window of the headways block', () {
      final q = lineQuality(day([hw(0.2)], from: 7, to: 21), '040', 0)!;
      expect([q.fromH, q.toH], [7, 21]);
    });
    test('only the shown direction counts; an unknown direction shows no pill', () {
      final d = day([hw(0.2, waitMin: 4, dir: 1)]);
      expect(lineQuality(d, '040', 0), isNull);
      expect(lineQuality(d, '040', null), isNull);
      expect(lineQuality(d, '040', 1)?.level, 3);
    });
    test('missing or malformed data shows nothing', () {
      expect(lineQuality(null, '040', 0), isNull);
      expect(lineQuality(QualityDay.fromJson({}), '040', 0), isNull);
      expect(lineQuality(day([hw(0.2, line: '041')]), '040', 0), isNull);
      expect(lineQuality(QualityDay.fromJson({'headways': {'by_line': 'x'}}), '040', 0), isNull);
      expect(lineQuality(day([{...hw(0.2), 'cv_h': '0.2'}]), '040', 0), isNull);
      // A day written before 2026-11-13 has no wait_min.
      expect(lineQuality(day([(hw(0.3))..remove('wait_min')]), '040', 0), isNull);
    });
  });

  group('pickDay: yesterday, else the day before', () {
    final y = day([]), b = day([hw(0.2)]);
    test('yesterday wins, even without data for the line', () {
      expect(pickDay(y, b)!.word, 'Χθες');
      expect(pickDay(y, b)!.back, 1);
      expect(pickDay(y, null)!.word, 'Χθες');
    });
    test('no file for yesterday yet: «Προχθές»', () {
      final p = pickDay(null, b)!;
      expect([p.word, p.back, identical(p.day, b)], ['Προχθές', 2, true]);
    });
    test('neither day: no pill', () => expect(pickDay(null, null), isNull));
  });

  test('lastDates: 7 dates ending at the given one, across a month end', () {
    expect(lastDates('2026-11-03', 7), ['2026-10-28', '2026-10-29', '2026-10-30', '2026-10-31', '2026-11-01', '2026-11-02', '2026-11-03']);
  });

  test('daysAgo is the Athens date', () {
    expect(daysAgo(DateTime.utc(2026, 11, 12, 10), 1), '2026-11-11'); // 12:00 Athens on 11-12
    expect(daysAgo(DateTime.utc(2026, 11, 12, 22, 30), 1), '2026-11-12'); // 00:30 Athens on 11-13
    expect(daysAgo(DateTime.utc(2026, 11, 12, 21, 59), 1), '2026-11-11'); // 23:59 Athens on 11-12
    expect(daysAgo(DateTime.utc(2026, 11, 12, 10), 2), '2026-11-10');
  });

  test('dayBars: one bar per day; a day without data is an empty slot', () {
    final bars = dayBars([('a', day([hw(0.8, waitMin: 9.2)])), ('b', null), ('c', day([hw(0.2, line: '041')]))], '040', 0);
    expect(bars.length, 3);
    expect([bars[0]!.date, bars[0]!.value, bars[0]!.level], ['a', 9.2, 1]);
    expect(bars[1], isNull);
    expect(bars[2], isNull);
  });

  group('matchDirection: the timetable direction going where the variant goes', () {
    final dirs = [
      {'direction': 0, 'headsign': 'ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ(ΠΡΟΣΩΡΙΝΗ ΛΟΓΩ ΕΡΓΩΝ)'},
      {'direction': 1, 'headsign': 'ΣΥΝΤΑΓΜΑ - ΠΕΙΡΑΙΑΣ'},
    ];
    test('the same last place, brackets, accents and spaces aside', () {
      expect(matchDirection(dirs, 'Πειραιάς - Σύνταγμα (22:00-06:00)'), 0);
      expect(matchDirection(dirs, 'ΣΥΝΤΑΓΜΑ - ΠΕΙΡΑΙΑΣ'), 1);
    });
    test('a name that contains the other', () {
      expect(matchDirection(dirs, 'ΑΛΛΗ - ΠΕΙΡΑΙΑΣ ΛΙΜΑΝΙ'), 1);
    });
    test('days at the end of an OASTH headsign are left out', () {
      final d = [
        {'direction': 0, 'headsign': 'ΑΓ. ΑΝΑΡΓΥΡΟΙ - ΚΟΡΔΕΛΙΟ'},
        {'direction': 1, 'headsign': 'ΚΟΡΔΕΛΙΟ - ΑΓ. ΑΝΑΡΓΥΡΟΙ'}
      ];
      expect(matchDirection(d, 'ΑΓ. ΑΝΑΡΓΥΡΟΙ - ΚΟΡΔΕΛΙΟ-ΣΑΒΒΑΤΟ-ΚΥΡΙΑΚΗ'), 0);
    });
    test('a timetable of one direction is the one of every variant; no match, no direction', () {
      expect(matchDirection([dirs[0]], 'ΚΥΚΛΙΚΗ'), 0);
      expect(matchDirection(dirs, 'ΧΑΛΑΝΔΡΙ'), isNull);
      expect(matchDirection(const [], 'ΧΑΛΑΝΔΡΙ'), isNull);
    });
  });

  group('Api.shownDay: one fetch per file per session', () {
    Api make(http.Response Function(Uri) f, List<String> asked) {
      final client = MockClient((r) async {
        asked.add(r.url.path);
        return f(r.url);
      });
      return Api(client: client, cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    }

    http.Response file(String date) => http.Response(
        jsonEncode({'version': 1, 'date': date, 'headways': {'by_line': [hw(0.3)]}}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});

    test('fetches days/<yesterday>.json once and shares it', () async {
      final asked = <String>[];
      final api = make((_) => file('2026-11-11'), asked);
      final now = DateTime.utc(2026, 11, 12, 10);
      final a = await api.shownDay(now: now), b = await api.shownDay(now: now.add(const Duration(hours: 5)));
      expect([a!.word, a.date], ['Χθες', '2026-11-11']);
      expect(identical(a.day, b!.day), isTrue);
      expect(asked, ['/angelospk/staseis-rt/stats/v1/days/2026-11-11.json']);
    });

    test('yesterday not written yet: the day before as «Προχθές»; yesterday asked again after an hour', () async {
      final asked = <String>[];
      var written = false;
      final api = make((u) => u.path.endsWith('2026-11-10.json') ? file('2026-11-10') : written ? file('2026-11-11') : http.Response('', 404), asked);
      final now = DateTime.utc(2026, 11, 12, 4);
      expect((await api.shownDay(now: now))!.word, 'Προχθές');
      expect((await api.shownDay(now: now.add(const Duration(minutes: 1))))!.word, 'Προχθές');
      expect(asked.length, 2); // yesterday (404), the day before; both kept for an hour
      written = true;
      final later = await api.shownDay(now: now.add(const Duration(hours: 1)));
      expect([later!.word, later.date], ['Χθες', '2026-11-11']);
    });

    test('Thessaloniki reads its own folder of the stats branch', () async {
      final asked = <String>[];
      final api = Api(
        client: MockClient((r) async {
          asked.add(r.url.path);
          return file('2026-11-11');
        }),
        cache: DiskCache(dir: Directory.systemTemp.createTempSync()),
        city: City.thessaloniki,
      );
      await api.shownDay(now: DateTime.utc(2026, 11, 12, 10));
      expect(asked.single, '/angelospk/staseis-rt/stats/v1/thessaloniki/days/2026-11-11.json');
    });

    test('neither day, another date or a failure gives null; a failure is asked again', () async {
      final asked = <String>[];
      var fail = true;
      final api = make((u) => fail ? throw const SocketException('offline') : file('2026-10-01'), asked);
      expect(await api.dayFile('2026-11-01', now: DateTime.utc(2026, 11, 12)), isNull);
      fail = false;
      expect(await api.dayFile('2026-11-01', now: DateTime.utc(2026, 11, 12)), isNull); // another date is not that day
      expect(asked.length, 2);
    });
  });
}
