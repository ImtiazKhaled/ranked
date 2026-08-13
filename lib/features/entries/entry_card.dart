import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/entry.dart';
import '../../providers/providers.dart';
import '../../theme/gradients.dart';
import '../../widgets/gradient_border_box.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/tier_badge.dart';

/// A single Pinterest-style card for an entry.
class EntryCard extends ConsumerWidget {
  const EntryCard({super.key, required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsNotifier = ref.read(tagsProvider.notifier);
    final tagNames = entry.tagIds
        .map((id) => tagsNotifier.byId(id)?.name)
        .whereType<String>()
        .toList();

    return GradientBorderBox(
      gradient: AppGradients.forSeed(entry.id),
      radius: 20,
      onTap: () => context.push('/entry/${entry.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.imageBytes != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.memory(
                entry.imageBytes!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TierBadge(tier: entry.tier),
                    const Spacer(),
                    if (entry.emotion != null)
                      _EmotionPill(
                        emoji: entry.emotion!.emoji,
                        label: entry.emotion!.label,
                        color: entry.emotion!.color,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry.summary,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (entry.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
                if (tagNames.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final name in tagNames)
                        TagChip(name: name, dense: true),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionPill extends StatelessWidget {
  const _EmotionPill({
    required this.emoji,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
