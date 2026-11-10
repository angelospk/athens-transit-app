import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/core/names.dart';
import 'package:flutter_test/flutter_test.dart';

// Port of the web's tests/nearby.test.ts (titleCase, v0.2.30).
void main() {
  test('names in capitals as names, no accents before the table is loaded', () {
    setAccents(null);
    expect(titleCase('ΑΓΙΑΣ ΤΡΙΑΔΟΣ'), 'Αγιας Τριαδος');
  });

  group('titleCase', () {
    setUpAll(() => setAccents((jsonDecode(File('assets/accents.json').readAsStringSync()) as List).cast<String>()));

    test('puts the accents OASA leaves out back, the first letter\'s too; an unknown word stays as written', () {
      expect(titleCase('ΠΛ. ΚΥΨΕΛΗΣ'), 'Πλ. Κυψέλης');
      expect(titleCase('ΑΓΙΑΣ ΤΡΙΑΔΟΣ'), 'Αγίας Τριάδος');
      expect(titleCase('ΑΓΙΟΣ ΔΗΜΗΤΡΙΟΣ'), 'Άγιος Δημήτριος');
      expect(titleCase('ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ'), 'Πειραιάς - Σύνταγμα');
      expect(titleCase('ΧΩΡΙΣΤΟΝΟΜΑΞΥΖ'), 'Χωριστονομαξυζ');
      expect(titleCase('ΠΛ ΚΥΨΕΛΗΣ (ΤΕΡΜΑ 036)'), 'Πλ Κυψέλης (Τέρμα 036)');
      expect(titleCase('ΣΤ.ΚΑΤΕΧΑΚΗ-ΓΑΛΑΤΣΙ'), 'Στ.Κατεχάκη-Γαλάτσι');
      expect(titleCase('Ήδη γραμμένο'), 'Ήδη γραμμένο');
      expect(titleCase('ΚΑΙΣΑΡΙΑΝΗ (Προσωρινή λόγω έργων)'), 'Καισαριανή (Προσωρινή λόγω έργων)');
      expect(titleCase('Α ΚΥΨΕΛΗ'), 'Α Κυψέλη');
      expect(titleCase('ΑΣ ΠΑΜΕ'), 'Ας Παμε'); // a final sigma in a two-letter word
    });

    test('Athens names the word lists lack, spelled by hand', () {
      expect(titleCase('ΑΡΓΥΡΟΥΠΟΛΕΩΣ'), 'Αργυρουπόλεως');
      expect(titleCase('ΚΑΛΟΓΡΕΖΑΣ'), 'Καλογρέζας');
      expect(titleCase('ΘΡΑΚΟΜΑΚΕΔΟΝΩΝ'), 'Θρακομακεδόνων');
      expect(titleCase('ΠΑΡΝΗΘΟΣ'), 'Πάρνηθος');
    });

    test('acronyms stay in capitals', () {
      expect(titleCase('ΙΚΑ ΚΥΨΕΛΗΣ'), 'ΙΚΑ Κυψέλης');
      expect(titleCase('ΣΤ. ΗΣΑΠ'), 'Στ. ΗΣΑΠ');
      expect(titleCase('ΟΤΕ'), 'ΟΤΕ');
      expect(titleCase('ΕΡΤ'), 'ΕΡΤ');
      expect(titleCase('ΛΑΣΚΑΡΕΩΣ'), 'Λασκάρεως');
    });

    test('Latin letters and digits as before', () {
      expect(titleCase('ΣΤΑΣΗ A1'), 'Στάση A1');
      expect(titleCase(''), '');
    });
  });
}
