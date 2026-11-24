// The ARB files agree: English has every Greek message and no other, with the same placeholders, every
// placeholder is declared in the template, and no text is empty.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String name) => jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

/// The messages: no `@key` metadata, no `@@locale`.
Map<String, String> _messages(Map<String, dynamic> arb) => {
      for (final e in arb.entries)
        if (!e.key.startsWith('@')) e.key: e.value as String,
    };

/// The placeholder names of an ICU message: `{name}`, and the argument of `{name, plural, …}` /
/// `{name, select, …}`, also inside the plural and select bodies. Literal text in quotes ('{') is skipped.
Set<String> placeholders(String msg) {
  final out = <String>{};
  void scan(String s) {
    var i = 0;
    while (i < s.length) {
      final c = s[i];
      if (c == "'" && i + 1 < s.length) {
        // ICU quoting: '' is a quote; '{…}' is literal.
        if (s[i + 1] == "'") {
          i += 2;
          continue;
        }
        if (s[i + 1] == '{' || s[i + 1] == '}') {
          final end = s.indexOf("'", i + 1);
          i = end < 0 ? s.length : end + 1;
          continue;
        }
      }
      if (c != '{') {
        i++;
        continue;
      }
      // The matching brace.
      var depth = 0, j = i;
      for (; j < s.length; j++) {
        if (s[j] == '{') depth++;
        if (s[j] == '}' && --depth == 0) break;
      }
      final inner = s.substring(i + 1, j.clamp(i + 1, s.length));
      final comma = inner.indexOf(',');
      if (comma < 0) {
        out.add(inner.trim());
      } else {
        out.add(inner.substring(0, comma).trim());
        // "plural, =1{…} other{…}": the bodies may name placeholders too; the keywords before each body
        // ("=1", "other", "male") are not placeholders.
        final rest = inner.substring(comma + 1);
        final comma2 = rest.indexOf(',');
        if (comma2 >= 0) {
          final bodies = rest.substring(comma2 + 1);
          var k = 0;
          while (k < bodies.length) {
            final open = bodies.indexOf('{', k);
            if (open < 0) break;
            var d = 0, m = open;
            for (; m < bodies.length; m++) {
              if (bodies[m] == '{') d++;
              if (bodies[m] == '}' && --d == 0) break;
            }
            scan(bodies.substring(open + 1, m.clamp(open + 1, bodies.length)));
            k = m + 1;
          }
        }
      }
      i = j + 1;
    }
  }

  scan(msg);
  return out;
}

void main() {
  final elArb = _arb('app_el.arb'), enArb = _arb('app_en.arb');
  final el = _messages(elArb), en = _messages(enArb);

  test('the placeholder parser', () {
    expect(placeholders('Το {line} σε {eta}'), {'line', 'eta'});
    expect(placeholders('{count, plural, =1{1 στάση} other{{count} στάσεις από {stop}}}'), {'count', 'stop'});
    expect(placeholders("{n, select, a{x} other{y}} '{literal}'"), {'n'});
    expect(placeholders('χωρίς'), isEmpty);
  });

  test('both languages have the same messages', () {
    expect(elArb['@@locale'], 'el');
    expect(enArb['@@locale'], 'en');
    expect(en.keys.toSet().difference(el.keys.toSet()), isEmpty, reason: 'in English only');
    expect(el.keys.toSet().difference(en.keys.toSet()), isEmpty, reason: 'not translated');
  });

  test('English has the same placeholders as Greek', () {
    final bad = <String>[
      for (final k in en.keys)
        if (el.containsKey(k) && !_sameSet(placeholders(en[k]!), placeholders(el[k]!)))
          '$k: en ${placeholders(en[k]!)} el ${placeholders(el[k]!)}',
    ];
    expect(bad, isEmpty);
  });

  test('every Greek placeholder is declared', () {
    final bad = <String>[];
    for (final k in el.keys) {
      final used = placeholders(el[k]!);
      if (used.isEmpty) continue;
      final meta = elArb['@$k'];
      final declared = meta is Map && meta['placeholders'] is Map ? (meta['placeholders'] as Map).keys.toSet() : <dynamic>{};
      final missing = used.where((p) => !declared.contains(p)).toList();
      if (missing.isNotEmpty) bad.add('$k: $missing');
    }
    expect(bad, isEmpty);
  });

  test('no text is empty', () {
    expect([for (final e in el.entries) if (e.value.trim().isEmpty) 'el ${e.key}'], isEmpty);
    expect([for (final e in en.entries) if (e.value.trim().isEmpty) 'en ${e.key}'], isEmpty);
  });
}

bool _sameSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);
