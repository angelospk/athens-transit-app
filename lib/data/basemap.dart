// The dark map style, lightened as on the web (core/basemap.dart), as a JSON string for MapLibre. The
// disk copy serves at once; the network refreshes it behind.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/basemap.dart';
import 'cache.dart';

const darkStyleUrl = 'https://tiles.openfreemap.org/styles/dark';

String? _memo;

Future<String?> darkStyle({DiskCache? cache, http.Client? client}) async {
  if (_memo != null) return _memo;
  final c = cache ?? DiskCache();
  Future<Map<String, dynamic>?> fetch() async {
    final r = await (client ?? http.Client()).get(Uri.parse(darkStyleUrl)).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return null;
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    await c.write('style_dark', j);
    return j;
  }

  var raw = await c.read('style_dark') as Map<String, dynamic>?;
  if (raw != null) {
    fetch().ignore();
  } else {
    try {
      raw = await fetch();
    } catch (_) {
      return null; // the map falls back to the plain dark style URL
    }
  }
  return raw == null ? null : _memo = jsonEncode(lightenDark(raw));
}
