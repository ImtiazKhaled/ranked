import 'package:flutter/material.dart';

/// Curated gradient palettes used for the coloured borders throughout the app.
class AppGradients {
  static const List<List<Color>> _palettes = [
    [Color(0xFF7C3AED), Color(0xFFEC4899)], // violet -> pink
    [Color(0xFF06B6D4), Color(0xFF3B82F6)], // cyan -> blue
    [Color(0xFF22C55E), Color(0xFF06B6D4)], // green -> cyan
    [Color(0xFFF59E0B), Color(0xFFEF4444)], // amber -> red
    [Color(0xFFEC4899), Color(0xFFF59E0B)], // pink -> amber
    [Color(0xFF8B5CF6), Color(0xFF06B6D4)], // purple -> cyan
  ];

  /// The signature app gradient (used for headers, the FAB, etc).
  static const LinearGradient brand = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// A stable gradient chosen from [_palettes] based on [seed].
  static LinearGradient forSeed(Object seed) {
    final palette = _palettes[seed.hashCode.abs() % _palettes.length];
    return LinearGradient(
      colors: palette,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
