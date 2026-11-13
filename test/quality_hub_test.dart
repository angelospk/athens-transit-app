// The hub keeps a line's live levels (contract rev 23) as the web v0.2.38 does: a refresh that fails or says
// warming_up keeps the last good ones, marked, for up to 10 minutes.
import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/core/live_quality.dart';
import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, Object?> body(String level) => {
      'line': 'oasa:040',
      'vehicles': [
        {'id': 'oasa:44548', 'quality': {'level': level, 'basis': 'headway', 'gap_s': 720, 'bunched': false}},
      ],
      'segments': <Object>[],
      'sources': [{'state': 'ok'}],
    };

void main() {
  late List<Uri> asked;
  late http.Response Function() answer;
  late int now;
  late LiveHub hub;

  setUp(() {
    asked = [];
    now = 1000000;
    answer = () => json(body('worse'));
    final api = Api(
      client: MockClient((r) async {
        asked.add(r.url);
        return answer();
      }),
      cache: DiskCache(dir: Directory.systemTemp.createTempSync()),
    );
    hub = LiveHub(api, clockMs: () => now);
  });

  test('asks /v2/lines/oasa:040/vehicles and keeps the levels by native vehicle id', () async {
    await hub.loadQuality(['040']);
    expect(asked.single.path, '/v2/lines/oasa%3A040/vehicles'); // as the web: encodeURIComponent
    final h = hub.qualityOf('040')!;
    expect([h.failed, h.value.levelOf('44548')], [false, QualityLevel.worse]);
    expect(hub.qualityOf('041'), isNull);
  });

  test('a line is asked at most every 10 s, whoever asks', () async {
    await hub.loadQuality(['040']);
    now += 5000;
    await hub.loadQuality(['040']);
    expect(asked, hasLength(1));
    now += 5000;
    await hub.loadQuality(['040']);
    expect(asked, hasLength(2));
  });

  for (final (name, make) in <(String, http.Response Function())>[
    ('503', () => json({'error': 'warming_up'}, 503)),
    ('a 502 HTML page', () => http.Response('<html>bad gateway</html>', 502)),
    ('a 200 that says warming_up', () => json({'sources': [{'state': 'warming_up'}], 'vehicles': <Object>[]})),
    ('a network error', () => throw const SocketException('offline')),
  ]) {
    test('$name keeps the last levels, marked failed', () async {
      await hub.loadQuality(['040']);
      final at = hub.qualityOf('040')!.at;
      answer = make;
      now += 20000;
      await hub.loadQuality(['040']);
      final h = hub.qualityOf('040')!;
      expect([h.failed, h.at, h.value.levelOf('44548')], [true, at, QualityLevel.worse]);
    });
  }

  test('after 10 minutes without a good answer the levels are gone', () async {
    await hub.loadQuality(['040']);
    answer = () => json({}, 503);
    now += 599000;
    await hub.loadQuality(['040']);
    expect(hub.qualityOf('040'), isNotNull);
    now += 11000;
    await hub.loadQuality(['040']);
    expect(hub.qualityOf('040'), isNull);
  });

  test('a good answer replaces the held ones and the version moves', () async {
    await hub.loadQuality(['040']);
    final v = hub.qualityVersion;
    answer = () => json(body('much_worse'));
    now += 20000;
    await hub.loadQuality(['040']);
    expect(hub.qualityOf('040')!.value.levelOf('44548'), QualityLevel.muchWorse);
    expect(hub.qualityVersion, greaterThan(v));
  });
}
