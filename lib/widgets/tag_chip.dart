import 'package:flutter/material.dart';

import '../utils/color_from_string.dart';

/// A small coloured pill for a tag. Colour is derived from the tag name so it
/// is consistent everywhere.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.name,
    this.selected = false,
    this.count,
    this.onTap,
    this.onRemove,
    this.dense = false,
  });

  final String name;
  final bool selected;
  final int? count;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = colorFromString(name);
    final bg =
        selected ? color.withValues(alpha: 0.85) : chipBackgroundFromString(name);
    final fg = selected
        ? Colors.white.withValues(alpha: 0.95)
        : chipTextFromString(name);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 12,
            vertical: dense ? 4 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: dense ? 12 : 13,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    fontSize: dense ? 11 : 12,
                  ),
                ),
              ],
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.close_rounded, size: 14, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
