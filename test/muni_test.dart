import 'package:athens_transit/core/muni.dart';
import 'package:athens_transit/ui/muni_panel.dart' show muniNextRows;
import 'package:flutter_test/flutter_test.dart';

// /v2/municipal (backend, OSM): line Α of Αγ. Δημήτριος both ways, and Χαλάνδρι Β1 / Β2 (two refs, one timetable group).
final _data = parseMunicipal({
  'attribution': '© OpenStreetMap contributors (ODbL)',
  'routes': [
    {
      'id': 'osm:r2', 'ref': 'Α', 'name': 'Γραμμή Α: Πλατεία → Νεκροταφείο', 'municipality': 'Δήμος Αγίου Δημητρίου',
      'timetable_url': 'https://dad.gr/x', 'shape': [[[37.93, 23.73], [37.94, 23.74]]], 'stops': ['n1', 'n2'],
    },
    {
      'id': 'osm:r1', 'ref': 'Α', 'name': 'Γραμμή Α: Νεκροταφείο → Πλατεία', 'municipality': 'Δήμος Αγίου Δημητρίου',
      'timetable_url': null, 'shape': [[[37.94, 23.74], [37.93, 23.73]]], 'stops': ['n2', 'n1'],
    },
    {
      'id': 'osm:r10', 'ref': 'Β1', 'name': 'Β1', 'municipality': 'Δήμος Χαλανδρίου',
      'timetable_url': 'javascript:alert(1)', 'shape': [[[38.02, 23.80], [38.03, 23.81]]], 'stops': ['n3'],
    },
    {
      'id': 'osm:r11', 'ref': 'Β2', 'name': 'Β2', 'municipality': 'Δήμος Χαλανδρίου',
      'timetable_url': null, 'shape': [[[38.03, 23.81], [38.02, 23.80]]], 'stops': ['n3', 'n9'],
    },
    {'id': 'bad', 'name': 'no municipality', 'shape': [], 'stops': []}, // dropped, not the whole body
  ],
  'stops': {
    'n1': {'name': 'Πλατεία', 'lat': 37.93, 'lon': 23.73},
    'n2': {'name': null, 'lat': 37.94, 'lon': 23.74},
    'n3': {'name': 'Πολύδροσο', 'lat': 38.02, 'lon': 23.80},
    'bad': {'name': 'x'},
  },
})!;

final _tables = parseMuniTimes({
  'v': 1,
  'tables': [
    {
      'municipality': 'Δήμος Χαλανδρίου', 'checked': '2026-11-05', 'valid': null, 'source': 'https://www.chalandri.gr/x',
      'lines': [
        {'routes': ['osm:r10'], 'ref': 'Β1', 'name': 'Πολύδροσο – Κοιμητήριο', 'group': 'Πολύδροσο ↔ Κοιμητήριο',
          'services': [{'days': [1, 2, 3, 4, 5], 'at': 'Πολύδροσο', 'times': ['08:50', '10:50', '12:50']}]},
        {'routes': ['osm:r11'], 'ref': 'Β2', 'name': 'Κοιμητήριο – Πολύδροσο', 'group': 'Πολύδροσο ↔ Κοιμητήριο',
          'services': [{'days': [1, 2, 3, 4, 5], 'at': 'Κοιμητήριο', 'times': ['09:20', '11:20']}]},
      ],
    },
    {
      'municipality': 'Δήμος Αγίου Δημητρίου', 'checked': '2026-11-05', 'source': 'https://dad.gr/x',
      'lines': [
        {'routes': ['osm:r1', 'osm:r2'], 'ref': 'Α', 'name': 'Γραμμή Α',
          'services': [
            {'days': [1, 2, 3, 4, 5], 'every': 20, 'first': '07:00', 'last': '09:00'},
            {'days': [6], 'season': {'from': '12-20', 'to': '01-07'}, 'label': 'Γιορτές', 'times': ['10:00']},
          ]},
      ],
    },
    // One wrong field drops this whole table, never the others: a typo must not show a wrong time.
    {
      'municipality': 'Δήμος Χ', 'checked': '2026-11-05', 'source': 'https://x',
      'lines': [{'routes': ['osm:r99'], 'name': 'Χ', 'services': [{'days': [1], 'times': ['09:00', '08:00']}]}],
    },
  ],
});

// A Monday 08:30 in Athens (EET, UTC+2 in November).
final _mon0830 = muniClock(DateTime.utc(2026, 11, 9, 6, 30));

// A record holding a List compares the list by identity: compare a flat string.
List<String> _next(MuniLine line, MuniClock clock, {int n = 3}) =>
    [for (final d in nextByStop(line, clock, n: n)) '${d.at} ${d.approx ? '~' : '='} ${d.times.join(' ')}'];

void main() {
  test('/v2/municipal: bad routes and stops are dropped; only a web link counts as the timetable page', () {
    expect(_data.routes.map((r) => r.id), ['osm:r2', 'osm:r1', 'osm:r10', 'osm:r11']);
    expect(_data.stops.keys, ['n1', 'n2', 'n3']);
    expect(_data.stops['n2']!.name, isNull);
    expect(_data.routes[0].shape, [
      [(37.93, 23.73), (37.94, 23.74)],
    ]);
    expect(_data.routes[0].timetableUrl, 'https://dad.gr/x');
    expect(_data.routes[2].timetableUrl, isNull); // javascript: is not a link
    expect(parseMunicipal({'routes': [], 'stops': {}}), isNull); // no data yet
    expect(parseMunicipal('not found'), isNull);
  });

  test('timetables: the file\'s tables, each checked whole', () {
    expect(_tables.map((t) => t.municipality), ['Δήμος Χαλανδρίου', 'Δήμος Αγίου Δημητρίου']);
    expect(_tables[0].valid, isNull);
    expect(_tables[1].lines.single.services[1].season, (from: '12-20', to: '01-07'));
    expect(parseMuniTimes({'v': 2, 'tables': []}), isEmpty); // a format we do not know
    expect(parseMuniTimes(null), isEmpty);
    // The checks of the web's parseTimetable: exactly one of times/every, valid days, real dates.
    List<MuniTable> one(Map<String, dynamic> service, {String checked = '2026-11-05'}) => parseMuniTimes({
          'v': 1,
          'tables': [
            {'municipality': 'Δ', 'checked': checked, 'source': 's', 'lines': [{'routes': ['r'], 'name': 'n', 'services': [service]}]},
          ],
        });
    expect(one({'days': [1], 'times': ['09:00']}), hasLength(1));
    expect(one({'days': [1], 'times': ['09:00']}, checked: '2026-02-30'), isEmpty);
    expect(one({'days': [8], 'times': ['09:00']}), isEmpty);
    expect(one({'days': [1, 1], 'times': ['09:00']}), isEmpty);
    expect(one({'days': [], 'times': ['09:00']}), isEmpty);
    expect(one({'days': [1], 'times': ['9:00']}), isEmpty);
    expect(one({'days': [1], 'times': ['24:00']}), isEmpty);
    expect(one({'days': [1], 'times': ['09:00'], 'every': 10, 'first': '09:00', 'last': '10:00'}), isEmpty);
    expect(one({'days': [1], 'every': 10, 'first': '10:00', 'last': '09:00'}), isEmpty);
    expect(one({'days': [1], 'every': 0, 'first': '09:00', 'last': '10:00'}), isEmpty);
    expect(one({'days': [1], 'season': {'from': '02-30', 'to': '03-01'}, 'times': ['09:00']}), isEmpty);
    expect(one({'days': [1], 'at': '  ', 'times': ['09:00']}), isEmpty);
  });

  test('the Athens clock: weekday, MM-DD and minute of the day, summer time included', () {
    expect(_mon0830, (md: '11-09', weekday: 1, minutes: 8 * 60 + 30));
    expect(muniClock(DateTime.utc(2026, 7, 5, 21, 15)), (md: '07-06', weekday: 1, minutes: 15)); // EEST, past midnight
  });

  test('next departures per stop they are timed at; a frequency is spelled out and marked approximate', () {
    final chal = _tables[0];
    expect(_next(chal.lines[0], _mon0830), ['Πολύδροσο = 08:50 10:50 12:50']);
    expect(_next(chal.lines[0], _mon0830, n: 1), ['Πολύδροσο = 08:50']);
    final a = _tables[1].lines.single;
    expect(_next(a, _mon0830), ['null ~ 08:40 09:00']);
    // A Saturday in the holiday season, across the new year; out of it, nothing.
    expect(_next(a, (md: '01-03', weekday: 6, minutes: 0)), ['null = 10:00']);
    expect(nextByStop(a, (md: '02-03', weekday: 6, minutes: 0)), isEmpty);
    // A time now still counts; one a minute ago does not.
    expect(nextByStop(chal.lines[0], (md: '11-09', weekday: 1, minutes: 12 * 60 + 50)).single.times, ['12:50']);
    expect(nextByStop(chal.lines[0], (md: '11-09', weekday: 1, minutes: 12 * 60 + 51)), isEmpty);
  });

  test('one card per line: both directions, by ref and by the timetable\'s group, the timetable\'s order first', () {
    final cards = muniCards(_data, _tables);
    expect(cards, hasLength(2));
    final a = cards.firstWhere((c) => c.municipality == 'Δήμος Αγίου Δημητρίου');
    expect(a.id, 'muni:r1'); // the smallest route id
    expect(a.ref, 'Α');
    expect(a.name, 'Γραμμή Α');
    expect(a.routes.map((r) => r.id), ['osm:r1', 'osm:r2']); // as the timetable lists them
    expect(a.table?.municipality, 'Δήμος Αγίου Δημητρίου');
    final b = cards.firstWhere((c) => c.municipality == 'Δήμος Χαλανδρίου');
    expect(b.ref, 'Β1');
    expect(b.name, 'Πολύδροσο ↔ Κοιμητήριο'); // the group
    expect(b.lines.map((l) => l.ref), ['Β1', 'Β2']);
    expect(b.stopIds, ['n3', 'n9']); // every stop of its routes, once
    // Without timetables: the route's name with the «Γραμμή Α:» prefix cut.
    final bare = muniCards(_data, const []);
    expect(bare.firstWhere((c) => c.ref == 'Α').name, 'Νεκροταφείο → Πλατεία');
    expect(bare.firstWhere((c) => c.ref == 'Α').table, isNull);
  });

  test('search: by ref, by municipality (Χολαργός finds Χολαργού), by name', () {
    final cards = muniCards(_data, _tables);
    expect(findMuniCards(cards, 'β1').map((c) => c.ref), ['Β1']);
    expect(findMuniCards(cards, 'Β').map((c) => c.ref), ['Β1']); // ref starts with
    expect(findMuniCards(cards, 'Χαλάνδρι').map((c) => c.ref), ['Β1']);
    expect(findMuniCards(cards, 'αγιος δημητριος').map((c) => c.ref), ['Α']);
    expect(findMuniCards(cards, 'κοιμητηριο').map((c) => c.ref), ['Β1']);
    expect(findMuniCards(cards, '  '), isEmpty);
    expect(findMuniCards(cards, 'πειραιας'), isEmpty);
  });

  test('a stop\'s cards: the lines through it', () {
    final cards = muniCards(_data, _tables);
    expect(cardsAtStop(cards, 'n3').map((c) => c.ref), ['Β1']);
    expect(cardsAtStop(cards, 'n1').map((c) => c.ref), ['Α']);
    expect(cardsAtStop(cards, 'zz'), isEmpty);
  });

  test('the sheet\'s rows: where each time leaves from; with two refs each row names its own', () {
    final cards = muniCards(_data, _tables);
    final b = cards.firstWhere((c) => c.ref == 'Β1');
    expect(muniNextRows(b, _mon0830), ['Β1: 08:50 · 10:50 · 12:50 από Πολύδροσο', 'Β2: 09:20 · 11:20 από Κοιμητήριο']);
    expect(muniNextRows(cards.firstWhere((c) => c.ref == 'Α'), _mon0830), ['≈ 08:40 · 09:00']);
  });
}
