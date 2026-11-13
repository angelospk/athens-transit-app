// The live levels' colours (contract rev 23: normal, worse, much_worse, unknown), as the web's app.css:
// `--lvt-*` for text on a card (4.5:1 on its ground, light and dark) and `--ontime/--late1/--late3/--none` for
// fills and outlines on the map.

import 'package:flutter/material.dart';

import '../core/live_quality.dart';
import 'theme.dart';

/// Text colour of a level on a card (the web's `.lvt-*`); unknown is the muted grey.
Color levelText(BuildContext context, QualityLevel level) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (level) {
    QualityLevel.normal => dark ? const Color(0xFF3FB95F) : const Color(0xFF1A7F37),
    QualityLevel.worse => dark ? const Color(0xFFD4A72C) : const Color(0xFF8A6500),
    QualityLevel.muchWorse => dark ? const Color(0xFFFF6B6B) : const Color(0xFFC92A2A),
    QualityLevel.unknown => context.tones.muted,
  };
}

/// Fill/outline colour of a level (the web's `--ontime`, `--late1`, `--late3`, `--none`), the same in both themes.
Color levelFill(QualityLevel level) => switch (level) {
      QualityLevel.normal => const Color(0xFF1A7F37),
      QualityLevel.worse => const Color(0xFFA87C00),
      QualityLevel.muchWorse => const Color(0xFFC92A2A),
      QualityLevel.unknown => const Color(0xFF6C757D),
    };
