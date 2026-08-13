import 'package:flutter/material.dart';

import '../models/tier.dart';

/// The coloured tier grade badge (S/A/B/C/D).
class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.tier, this.size = 34});

  final Tier tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: tier.gradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: tier.colorEnd.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        tier.label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: size * 0.5,
          color: Colors.black.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}
