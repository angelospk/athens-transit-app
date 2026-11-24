// A refresh that fails never empties a good list (port of the web's src/lib/held.ts, v0.2.38). While the backend
// restarts or is overloaded (5xx, a timeout, a body whose source says `warming_up`), the last good list stays,
// marked, for up to [heldMaxMs]. A good answer replaces it, also an empty one (night): "good" is decided by the
// status and the shape of the body, not by its size.

const heldMaxMs = 600000; // a position this old is not "now" either

class Held<T> {
  const Held(this.value, this.at, {this.failed = false});
  final T value;
  final int at; // ms epoch of the last good answer
  final bool failed; // the latest refresh did not give a good one

  Held<T> markFailed() => Held(value, at, failed: true);
}

/// A /v2 body of a source that is still loading: `{"sources":[{"state":"warming_up"}],"lines":[],...}`.
bool isWarmingBody(Object? body) {
  final s = body is Map ? body['sources'] : null;
  return s is List && s.any((x) => x is Map && x['state'] == 'warming_up');
}

/// [status]: the HTTP status, 0 for a network error or a timeout. [parse]: the body as the list we hold, or null
/// when it is not of the expected shape.
Held<T>? refreshHeld<T>(Held<T>? held, int status, Object? body, T? Function(Object?) parse, int nowMs) {
  final value = status == 200 && !isWarmingBody(body) ? parse(body) : null;
  if (value != null) return Held(value, nowMs);
  return held != null && nowMs - held.at < heldMaxMs ? held.markFailed() : null;
}

/// One short neutral line while a held list is not fresh; no second person.
String? heldNote(Held<Object?>? held, int nowMs) {
  if (held == null || !held.failed) return null;
  final s = ((nowMs - held.at) ~/ 1000).clamp(0, 1 << 30);
  return 'Ενημέρωση σε εξέλιξη · τελευταία θέση πριν από ${s < 60 ? '$s″' : '${s ~/ 60}′'}';
}
