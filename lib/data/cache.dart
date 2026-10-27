// JSON files in the app's support directory: static data, the trip index and the last live copy of
// each line (what the offline estimate starts from).

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DiskCache {
  DiskCache({this.dir});

  Directory? dir;

  Future<File> _file(String key) async {
    dir ??= Directory('${(await getApplicationSupportDirectory()).path}/cache');
    await dir!.create(recursive: true);
    return File('${dir!.path}/${Uri.encodeComponent(key)}.json');
  }

  Future<dynamic> read(String key) async {
    try {
      final f = await _file(key);
      return await f.exists() ? jsonDecode(await f.readAsString()) : null;
    } catch (_) {
      return null; // a broken file is as good as none
    }
  }

  Future<void> write(String key, Object? json) async {
    final f = await _file(key);
    // Own temp name per write: the UI and the alert service isolates may write the same key.
    final tmp = File('${f.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.tmp');
    await tmp.writeAsString(jsonEncode(json));
    await tmp.rename(f.path);
  }
}
