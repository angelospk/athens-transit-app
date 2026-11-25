// The map's setup per style load (ui/map_screen.dart). iOS (maplibre_gl 0.27) can report one style
// load twice: the second call joins the first.

class StyleLoads {
  Future<void>? _running;

  /// Runs [setup] for a style load. [current] is false once a newer load started.
  Future<void> load(Future<void> Function(bool Function() current) setup) =>
      _running ??= setup(() => true).whenComplete(() => _running = null);

  /// Fills the style's data (metro lines, rail lines, stops).
  Future<void> fill(Map<String, Future<void> Function()> fills) async {
    await Future.wait([
      for (final f in fills.values)
        () async {
          try {
            await f();
          } catch (_) {}
        }(),
    ]);
  }
}
