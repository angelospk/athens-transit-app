// A stop with no bus near it still needs the line's static data: its runs that have not started yet
// come from the timetable + the stop's place on the route (QA, 05:00, a stop with no live bus).
import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loadStatics loads the lines it is given, skips failures, keeps what it has', () async {
    final asked = <String>[];
    final api = Api(
      client: MockClient((r) async {
        asked.add(r.url.path);
        if (r.url.path.endsWith('/T1.json')) {
          return http.Response(jsonEncode({'id': 'T1', 'variants': {}, 'stops': {}}), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('no', 500);
      }),
      cache: DiskCache(dir: Directory.systemTemp.createTempSync()),
    );
    final live = LiveHub(api);
    await live.loadStatics(['T1', 'T2']);
    expect(live.statics.keys, ['T1']);
    final n = asked.length;
    await live.loadStatics(['T1']);
    expect(asked.length, n, reason: 'a loaded line is not asked again');
  });
}
