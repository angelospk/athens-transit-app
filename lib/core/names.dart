// OASA writes names in capitals, with no accents: each word in capitals is shown as a name (its first letter up, the
// rest down), with its accent back (assets/accents.json, the web's src/lib/accents.json, built by its
// scripts/accents.py: «ΑΓΙΑΣ ΤΡΙΑΔΟΣ» → «Αγίας Τριάδος»); a word the table lacks stays without one. Acronyms stay in
// capitals. Port of the web's titleCase (src/lib/nearby.ts, v0.2.30). Search folds the accents away (nearby.dart fold).

import 'dart:convert';

import 'package:flutter/services.dart';

const _plain = {'ά': 'α', 'έ': 'ε', 'ή': 'η', 'ί': 'ι', 'ϊ': 'ι', 'ΐ': 'ι', 'ό': 'ο', 'ύ': 'υ', 'ϋ': 'υ', 'ΰ': 'υ', 'ώ': 'ω', 'ς': 'σ'};
final _accented = RegExp('[ΆΈΉΊΌΎΏΪΫάέήίόύώϊϋΐΰ]');
final _word = RegExp(r'\p{L}+', unicode: true);

String _foldWord(String w) => w.toLowerCase().split('').map((c) => _plain[c] ?? c).join();

Map<String, String>? _accents;

/// The word table (accented, lower case). Null drops it.
void setAccents(List<String>? words) => _accents = words == null ? null : {for (final a in words) _foldWord(a): a};

/// Loads assets/accents.json; on a failure names show without accents.
Future<void> loadAccents() async {
  try {
    setAccents((jsonDecode(await rootBundle.loadString('assets/accents.json')) as List).cast<String>());
  } catch (_) {}
}

const _acronyms = {'ΙΚΑ', 'ΟΤΕ', 'ΗΣΑΠ', 'ΔΕΗ', 'ΕΥΔΑΠ', 'ΚΑΠΗ', 'ΟΑΕΔ', 'ΤΥΠΕΤ', 'ΕΚΑΒ', 'ΚΑΤ', 'ΚΤΕΛ', 'ΟΑΚΑ', 'ΤΕΙ', 'ΕΛΤΑ', 'ΟΣΕ', 'ΣΕΦ', 'ΟΑΣΑ', 'ΕΡΤ', 'ΕΟΤ'};

String titleCase(String s) => s.replaceAllMapped(_word, (m) {
      final w = m[0]!;
      if (w.length < 2 || w != w.toUpperCase() || _acronyms.contains(w)) return w;
      var low = w.toLowerCase();
      if (low.endsWith('σ')) low = '${low.substring(0, low.length - 1)}ς'; // Dart's lower case has no final sigma
      final a = _accented.hasMatch(w) ? low : _accents?[_foldWord(w)] ?? low;
      return a[0].toUpperCase() + a.substring(1);
    });
