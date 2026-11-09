// «Λάθος θέση στάσης;» (as the web's stopfix.ts): the user taps where the pole stands and the report goes
// out as feedback text. Its #stopfix line is the web's, so the web's scripts/stopfix.ts reads app reports
// too. Nothing moves on the map by itself: a person commits a correction when GPS or 3+ reports agree.

import 'geo.dart';

const maxMoveM = 80; // a pin further than this from the map's stop is not sent
const minMoveM = 3; // closer: the pin did not move

bool fixSendable(num m) => m >= minMoveM && m <= maxMoveM;

String _f6(double x) => x.toStringAsFixed(6);

/// The feedback text: a line for people, then the machine line.
String stopReportText({
  required String stop,
  required String name,
  required Pt from,
  required Pt at,
  required String device,
}) =>
    'Λάθος θέση στάσης $name ($stop): ${distM(from, at).round()} μ από τη θέση του χάρτη.\n'
    '#stopfix stop=$stop lat=${_f6(at.$1)} lon=${_f6(at.$2)} from=${_f6(from.$1)},${_f6(from.$2)} dev=$device';

/// Google Street View at [p] (a plain Maps URL, no key), to see where the pole stands.
String streetViewUrl(Pt p) => 'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${_f6(p.$1)},${_f6(p.$2)}';
