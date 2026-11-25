// The map's setup per style load (ui/map_screen.dart). A new style starts empty: the dark style URL
// is replaced by the lightened style (data/basemap.dart) while the first setup can still run, and a
// theme switch loads another style. So each style load gets its own setup, after the one before; an
// older setup stops at its next step. iOS (maplibre_gl 0.27) can report one load twice: the setup
// skips what the style already has.
//
// The style's data (metro lines, rail lines, stops) is filled after its setup. A fill that failed
// (offline at the start) is tried again at the next call, until it is done on this style.

class StyleLoads {
  int _gen = 0;
  Future<void> _last = Future.value();
  final _done = <String>{};
  final _busy = <String>{};

  /// Runs [setup] for a style load, after the setup before it. [current] is false once a newer load
  /// started.
  Future<void> load(Future<void> Function(bool Function() current) setup) {
    final gen = ++_gen;
    _done.clear();
    bool current() => gen == _gen;
    final run = _last.catchError((Object _) {}).then((_) => current() ? setup(current) : null);
    _last = run;
    return run;
  }

  /// Fills the style's data: each fill not done on this style and not running yet. Errors stay
  /// here: a failed fill is tried again at the next call.
  Future<void> fill(Map<String, Future<void> Function()> fills) async {
    final gen = _gen;
    await Future.wait([
      for (final MapEntry(:key, :value) in fills.entries)
        if (!_done.contains(key) && _busy.add(key))
          () async {
            try {
              await value();
              if (gen == _gen) _done.add(key);
            } catch (_) {
              // tried again at the next call
            } finally {
              _busy.remove(key);
            }
          }(),
    ]);
  }
}
