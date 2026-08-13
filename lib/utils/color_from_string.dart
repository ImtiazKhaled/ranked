import 'package:flutter/material.dart';

/// Deterministic, pleasant colour for a given string (used for tag colours).
/// The same name always maps to the same hue, so tag colours stay consistent
/// across the whole app and across sessions.
Color colorFromString(String input) {
  final hue = _stableHue(input);
  return HSLColor.fromAHSL(1, hue, 0.62, 0.55).toColor();
}

/// A soft, light tinted background variant of the tag colour for chips
/// (reads well on a light surface).
Color chipBackgroundFromString(String input) {
  final hue = _stableHue(input);
  return HSLColor.fromAHSL(1, hue, 0.68, 0.90).toColor();
}

/// A darker, readable variant of the tag colour for chip text on a light tint.
Color chipTextFromString(String input) {
  final hue = _stableHue(input);
  return HSLColor.fromAHSL(1, hue, 0.62, 0.38).toColor();
}

double _stableHue(String input) {
  var hash = 0;
  for (final codeUnit in input.toLowerCase().codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7fffffff;
  }
  return (hash % 360).toDouble();
}
