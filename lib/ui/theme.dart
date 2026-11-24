// Colours and type shared with the web (athens-transit-map docs/design-unify-2026-11.md; its src/app.css has the
// same values): warm neutrals, one ink, one deep blue accent, line colours from the Okabe-Ito palette.
// Names here vs the web: ground = ground (--bg), card = surface, surface = surface-2 (--control), rule = rule.

import 'package:flutter/material.dart';

class Tones extends ThemeExtension<Tones> {
  const Tones({
    required this.ground,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.rule,
    required this.indicator,
    required this.late,
    required this.onTime,
    required this.problemBg,
    required this.problemFg,
    required this.mapGround,
    required this.accent,
    required this.outline,
    required this.card,
    required this.accentSoft,
    required this.onAccent,
    required this.star,
    required this.plate,
    required this.plateEdge,
    required this.amber,
  });

  final Color ground, surface, ink, muted, rule, indicator, late, onTime, problemBg, problemFg, mapGround;
  final Color accent, outline; // actions and the smart card's minutes; the walk button's edge
  final Color card, accentSoft, onAccent, star; // a card on the ground; a selected wash; text on accent; a starred favourite
  // The board plate: every LIVE arrival time sits on a dark plate with amber digits. Amber is used nowhere else.
  final Color plate, plateEdge, amber; // the plate's fill (same in both themes); its 1 px edge (dark theme only); the digits

  static const light = Tones(
    ground: Color(0xFFF7F7F4),
    surface: Color(0xFFEFF0EC),
    ink: Color(0xFF16181B),
    muted: Color(0xFF5C626A),
    rule: Color(0xFFE3E4DF),
    indicator: Color(0xFFE7EEFB),
    late: Color(0xFFB4470B),
    onTime: Color(0xFF146C2E),
    problemBg: Color(0xFFF9DEDC),
    problemFg: Color(0xFF410E0B),
    mapGround: Color(0xFFE9ECE6),
    accent: Color(0xFF1A56C4),
    outline: Color(0xFFCFD6E0),
    card: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE7EEFB),
    onAccent: Color(0xFFFFFFFF),
    star: Color(0xFFE8A100),
    plate: Color(0xFF16181B),
    plateEdge: Color(0x00000000),
    amber: Color(0xFFFFB000),
  );

  static const dark = Tones(
    ground: Color(0xFF0F1113),
    surface: Color(0xFF24282C),
    ink: Color(0xFFECEDE9),
    muted: Color(0xFFA3A9B1),
    rule: Color(0xFF2E3337),
    indicator: Color(0xFF1C2C47),
    late: Color(0xFFFFB25C),
    onTime: Color(0xFF7DD99A),
    problemBg: Color(0xFF5C1F1B),
    problemFg: Color(0xFFFFDAD6),
    mapGround: Color(0xFF1B1E1C),
    accent: Color(0xFF8AB4F8),
    outline: Color(0xFF4A5560),
    card: Color(0xFF181B1E),
    accentSoft: Color(0xFF1C2C47),
    onAccent: Color(0xFF0B1B3A),
    star: Color(0xFFF5B83D),
    plate: Color(0xFF16181B),
    plateEdge: Color(0xFF30353A),
    amber: Color(0xFFFFB000),
  );

  @override
  Tones copyWith() => this;

  @override
  Tones lerp(Tones? other, double t) => t < .5 ? this : other ?? this;
}

// Radius, type and spacing shared with the web (docs/design-unify-2026-11.md §2; the web's --r-*, --fs-*).
abstract final class Ds {
  static const rXs = 6.0, rSm = 8.0, rMd = 12.0, rLg = 16.0, rXl = 24.0, rPill = 999.0;
  static const gutter = 16.0;
  static const tabular = [FontFeature.tabularFigures()];
  static const titleLg = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.2);
  static const title = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.25);
  static const bodyStrong = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const meta = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
  static const note = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600);
  static const eyebrow = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.7);
  static const badge = TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.15, fontFeatures: tabular);

  // A card on the ground: white (dark: surface), a 1 px rule, radius 16, no shadow.
  static BoxDecoration card(Tones t) =>
      BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(rLg), border: Border.all(color: t.rule));
}

extension TonesOf on BuildContext {
  Tones get tones => Theme.of(this).extension<Tones>()!;
}

ThemeData buildTheme(Brightness b) {
  final t = b == Brightness.light ? Tones.light : Tones.dark;
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0072B2), brightness: b).copyWith(
    surface: t.ground,
    onSurface: t.ink,
    primary: t.ink,
    onPrimary: t.ground,
    secondaryContainer: t.indicator,
    onSecondaryContainer: t.ink,
    outline: const Color(0xFF74777F),
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: t.ground,
    extensions: [t],
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.surface,
      indicatorColor: t.indicator,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(fontSize: 12, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500, color: t.ink),
      ),
    ),
    textTheme: const TextTheme(
      headlineSmall: Ds.titleLg, // a card's title (stop, station), as the web's h2
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    ),
  );
}

// Line colours: each of the user's lines keeps a slot of the palette (lineColors.ts on the web).
class LineColor {
  const LineColor(this.bg, this.fg);
  final Color bg, fg;
}

const palette = [
  LineColor(Color(0xFF0072B2), Colors.white),
  LineColor(Color(0xFFE69F00), Colors.black),
  LineColor(Color(0xFF009E73), Colors.black),
  LineColor(Color(0xFFCC79A7), Colors.black),
  LineColor(Color(0xFF56B4E9), Colors.black),
  LineColor(Color(0xFFD55E00), Colors.black),
];

String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
