import 'package:flutter/material.dart';

import '../../models/tier.dart';

/// Row of selectable S/A/B/C/D tier badges.
class TierSelector extends StatelessWidget {
  const TierSelector({super.key, required this.value, required this.onChanged});

  final Tier value;
  final ValueChanged<Tier> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tier in Tier.values) ...[
          _TierOption(
            tier: tier,
            selected: tier == value,
            onTap: () => onChanged(tier),
          ),
          if (tier != Tier.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _TierOption extends StatelessWidget {
  const _TierOption({
    required this.tier,
    required this.selected,
    required this.onTap,
  });

  final Tier tier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? tier.gradient : null,
          color: selected ? null : const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.9)
                : tier.colorStart.withValues(alpha: 0.5),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: tier.colorEnd.withValues(alpha: 0.5),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Text(
          tier.label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: selected
                ? Colors.black.withValues(alpha: 0.85)
                : tier.colorStart,
          ),
        ),
      ),
    );
  }
}
