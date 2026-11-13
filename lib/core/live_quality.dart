// Live quality levels of contract rev 23 (athens-transit-rt docs/QUALITY.md; port of the web's src/lib/liveQuality.ts).
// One scale for every level: green, yellow, red, grey. Pure: no widgets, no network.

enum QualityLevel {
  normal,
  worse,
  muchWorse,
  unknown;

  /// The API's word; a value this version does not know is shown as unknown, as the contract asks.
  static QualityLevel parse(Object? v) => switch (v) {
        'normal' => normal,
        'worse' => worse,
        'much_worse' => muchWorse,
        _ => unknown,
      };

  /// A level with a colour: not unknown.
  bool get live => this != unknown;
}
