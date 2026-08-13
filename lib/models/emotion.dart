import 'package:flutter/material.dart';

import '../data/emotion_wheel_data.dart';

/// A concrete emotion selection stored on an entry: the full path through the
/// wheel (primary -> secondary -> tertiary) plus the leaf emoji for display.
class EmotionRef {
  final String primary;
  final String secondary;
  final String tertiary;
  final String emoji;

  const EmotionRef({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.emoji,
  });

  /// The leaf (most specific) label.
  String get label => tertiary;

  /// Colour derived from the owning primary emotion.
  Color get color => primaryEmotionColor(primary);

  String get path => '$primary › $secondary › $tertiary';

  Map<String, dynamic> toMap() => {
        'primary': primary,
        'secondary': secondary,
        'tertiary': tertiary,
        'emoji': emoji,
      };

  static EmotionRef? fromMap(Map? map) {
    if (map == null) return null;
    return EmotionRef(
      primary: map['primary'] as String? ?? '',
      secondary: map['secondary'] as String? ?? '',
      tertiary: map['tertiary'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🙂',
    );
  }
}
