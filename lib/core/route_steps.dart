// A planned trip as the steps to follow: walk to the stop, which bus and where to get off, the
// change, the metro, the walk to the end. For the route screen; the minutes are the planner's
// estimates (walking 4.5 km/h on streets, the bus 15 km/h with its stops, the metro 30 km/h).

import 'dart:math';

import 'geo.dart';
import 'leave.dart' show walkMinutes;
import 'models.dart';
import 'trip.dart';

enum StepKind { walk, bus, metro }

const _stepWalkM = 40.0; // closer is the same place: no walk step
const metroWaitMin = 5; // the planner's wait for a train

class RouteStep {
  final StepKind kind;
  final String? line, variant; // bus or metro line; the bus's variant
  final String from, to; // stop or station names; '' for the trip's own start or end
  final String? toward; // the bus's last stop (where it goes)
  final Pt? fromAt, toAt; // null: the trip's own start or end
  final int? i, j; // board and get-off index in the variant's stops
  final int stops, min; // stops on the bus; estimated minutes on the way
  final int wait; // minutes waiting before this step (a change, the metro)
  const RouteStep({
    required this.kind,
    this.line,
    this.variant,
    required this.from,
    required this.to,
    this.toward,
    this.fromAt,
    this.toAt,
    this.i,
    this.j,
    this.stops = 0,
    required this.min,
    this.wait = 0,
  });
}

int totalMinutes(List<RouteStep> steps) => steps.fold(0, (a, s) => a + s.min + s.wait);

double _nearestM(Pt p, List<Pt> pts) => pts.map((q) => distM(p, q)).reduce(min);

RouteStep? _walk(String from, String to, Pt? fromAt, Pt? toAt, double m) =>
    m < _stepWalkM ? null : RouteStep(kind: StepKind.walk, from: from, to: to, fromAt: fromAt, toAt: toAt, min: walkMinutes(m));

RouteStep _bus(TripIndex ix, String line, String variant, int i, int j, int from, int to, int stops, double ride, {int wait = 0}) {
  final a = ix.s[from], b = ix.s[to];
  final seq = ix.l[line]?[variant];
  return RouteStep(
    kind: StepKind.bus,
    line: line,
    variant: variant,
    from: a.$1,
    to: b.$1,
    toward: seq == null || seq.isEmpty ? null : ix.s[seq.last].$1,
    fromAt: (a.$2, a.$3),
    toAt: (b.$2, b.$3),
    i: i,
    j: j,
    stops: stops,
    min: max(1, rideMinutes(ride).round()),
    wait: wait,
  );
}

/// One bus: walk to its stop, ride, walk from the stop to the end.
List<RouteStep> directSteps(TripIndex ix, TripLine r, {required List<Pt> from, required List<Pt> to}) {
  final v = r.variants.first;
  final bus = _bus(ix, r.line, v.id, v.i, v.j, v.from, v.to, v.stops, v.ride);
  return [
    ?_walk('', bus.from, null, bus.fromAt, _nearestM(bus.fromAt!, from)),
    bus,
    ?_walk(bus.to, '', bus.toAt, null, _nearestM(bus.toAt!, to)),
  ];
}

/// Two buses: the first, the walk across to the second's stop, the wait, the second.
List<RouteStep> transferSteps(TripIndex ix, TripTransfer c, {required List<Pt> from, required List<Pt> to}) {
  final a = c.legs.first, b = c.legs.last;
  final first = _bus(ix, a.line, a.id, a.i, a.j, a.from, a.to, a.stops, a.ride);
  final second = _bus(ix, b.line, b.id, b.i, b.j, b.from, b.to, b.stops, b.ride, wait: xferMin.round());
  return [
    ?_walk('', first.from, null, first.fromAt, _nearestM(first.fromAt!, from)),
    first,
    ?_walk(first.to, second.from, first.toAt, second.fromAt, c.xfer),
    second,
    ?_walk(second.to, '', second.toAt, null, _nearestM(second.toAt!, to)),
  ];
}

RouteStep _metro(String line, MetroStation a, MetroStation b) => RouteStep(
      kind: StepKind.metro,
      line: line,
      from: a.name,
      to: b.name,
      fromAt: (a.lat, a.lon),
      toAt: (b.lat, b.lon),
      min: max(1, (distM((a.lat, a.lon), (b.lat, b.lon)) / 500).round()),
      wait: metroWaitMin,
    );

MetroStation? _station(List<MetroStation> stations, String name) => stations.where((s) => s.name == name).firstOrNull;

/// The metro (or tram) alone: walk to the station, ride, walk to the end. Empty when a station is unknown.
List<RouteStep> metroSteps(List<MetroStation> stations, ({String line, String from, String to, double walk}) m,
    {required List<Pt> from, required List<Pt> to}) {
  final a = _station(stations, m.from), b = _station(stations, m.to);
  if (a == null || b == null) return const [];
  return [
    ?_walk('', a.name, null, (a.lat, a.lon), _nearestM((a.lat, a.lon), from)),
    _metro(m.line, a, b),
    ?_walk(b.name, '', (b.lat, b.lon), null, _nearestM((b.lat, b.lon), to)),
  ];
}

/// A bus and the metro, in either order (trip.dart `busMetro`). Empty when a station is unknown.
List<RouteStep> comboSteps(TripIndex ix, List<MetroStation> stations,
    ({TripLine bus, String station, String metroLine, String metroTo, bool busFirst, double min}) c,
    {required List<Pt> from, required List<Pt> to}) {
  final a = _station(stations, c.station), b = _station(stations, c.metroTo);
  if (a == null || b == null) return const [];
  final metro = _metro(c.metroLine, a, b);
  if (c.busFirst) {
    // The bus was planned to the station: its last walk ends there, then the train.
    final bus = directSteps(ix, c.bus, from: from, to: [(a.lat, a.lon)]);
    return [
      for (final s in bus)
        if (s.kind == StepKind.walk && s.toAt == null) RouteStep(kind: StepKind.walk, from: s.from, to: a.name, fromAt: s.fromAt, toAt: (a.lat, a.lon), min: s.min) else s,
      metro,
      ?_walk(b.name, '', (b.lat, b.lon), null, _nearestM((b.lat, b.lon), to)),
    ];
  }
  final bus = directSteps(ix, c.bus, from: [(b.lat, b.lon)], to: to);
  return [
    ?_walk('', a.name, null, (a.lat, a.lon), _nearestM((a.lat, a.lon), from)),
    metro,
    for (final s in bus)
      if (s.kind == StepKind.walk && s.fromAt == null) RouteStep(kind: StepKind.walk, from: b.name, to: s.to, fromAt: (b.lat, b.lon), toAt: s.toAt, min: s.min) else s,
  ];
}
