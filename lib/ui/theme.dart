// Colours and type from the mockups (claude.ai artifact "Athens Transit App mockups", System board):
// calm neutrals, one ink, line colours from the Okabe-Ito palette, delay in amber, on time in green.

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
  });

  final Color ground, surface, ink, muted, rule, indicator, late, onTime, problemBg, problemFg, mapGround;

  static const light = Tones(
    ground: Color(0xFFFCFCFA),
    surface: Color(0xFFF2F3F0),
    ink: Color(0xFF1A1C1E),
    muted: Color(0xFF43474E),
    rule: Color(0xFFE1E3DF),
    indicator: Color(0xFFD7E0E8),
    late: Color(0xFF7A4F00),
    onTime: Color(0xFF146C2E),
    problemBg: Color(0xFFF9DEDC),
    problemFg: Color(0xFF410E0B),
    mapGround: Color(0xFFE9ECE6),
  );

  static const dark = Tones(
    ground: Color(0xFF111315),
    surface: Color(0xFF1D2023),
    ink: Color(0xFFE3E3E0),
    muted: Color(0xFFB4B8BF),
    rule: Color(0xFF33373B),
    indicator: Color(0xFF3A4652),
    late: Color(0xFFFFB951),
    onTime: Color(0xFF7DD99A),
    problemBg: Color(0xFF5C1F1B),
    problemFg: Color(0xFFFFDAD6),
    mapGround: Color(0xFF1B1E1C),
  );

  @override
  Tones copyWith() => this;

  @override
  Tones lerp(Tones? other, double t) => t < .5 ? this : other ?? this;
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
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
