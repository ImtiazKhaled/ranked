import 'package:flutter/material.dart';

/// The "score" attached to an entry: a tier grade S > A > B > C > D.
enum Tier {
  s('S', Color(0xFFFFD54A), Color(0xFFFF8A3D)), // gold -> orange
  a('A', Color(0xFF4ADE80), Color(0xFF16A34A)), // greens
  b('B', Color(0xFF38BDF8), Color(0xFF2563EB)), // blues
  c('C', Color(0xFFFB923C), Color(0xFFF97316)), // oranges
  d('D', Color(0xFFF87171), Color(0xFFDC2626)); // reds

  const Tier(this.label, this.colorStart, this.colorEnd);

  final String label;
  final Color colorStart;
  final Color colorEnd;

  LinearGradient get gradient => LinearGradient(
        colors: [colorStart, colorEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static Tier fromLabel(String label) =>
      Tier.values.firstWhere((t) => t.label == label, orElse: () => Tier.c);
}
