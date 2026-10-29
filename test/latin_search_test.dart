import 'package:athens_transit/core/nearby.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Latin letters find Greek names, the way people type them', () {
    expect(nameMatches('ΣΥΝΤΑΓΜΑ', 'syntagma'), isTrue);
    expect(nameMatches('ΣΥΝΤΑΓΜΑ', 'sintagma'), isTrue);
    expect(nameMatches('ΚΗΦΙΣΙΑ', 'Kifisia'), isTrue);
    expect(nameMatches('ΠΕΙΡΑΙΑΣ', 'peir'), isTrue);
    expect(nameMatches('ΧΑΛΑΝΔΡΙ', 'chalandri'), isTrue);
    expect(nameMatches('ΧΑΛΑΝΔΡΙ', 'halandri'), isTrue);
    expect(nameMatches('ΘΗΣΕΙΟ', 'thiseio'), isTrue);
    expect(nameMatches('ΑΚΡΟΠΟΛΗ', 'syntagma'), isFalse);
    // ου is «ou», not «oi».
    expect(nameMatches('ΜΑΡΟΥΣΙ', 'marousi'), isTrue);
    expect(nameMatches('ΒΟΥΛΑ', 'voula'), isTrue);
    expect(nameMatches('ΗΛΙΟΥΠΟΛΗ', 'ilioupoli'), isTrue);
  });

  test('Greek still matches as before: no accents, any case', () {
    expect(nameMatches('ΣΥΝΤΑΓΜΑ', 'σύνταγ'), isTrue);
    expect(nameMatches('ΣΥΝΤΑΓΜΑ', 'ομον'), isFalse);
  });

  test('the planner: a Latin query finds places, a Greek one keeps its word-start rule', () {
    expect(latinMatches('ΣΥΝΤΑΓΜΑ', 'syntagma'), isTrue);
    expect(latinMatches('ΔΙΑΣΤΑΥΡΩΣΗ', 'ταυρ'), isFalse);
  });
}
