import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tag_chip.dart';
import 'entry_card.dart';

class ListScreen extends ConsumerWidget {
  const ListScreen({super.key});

  int _columnsForWidth(double width) {
    if (width >= 1500) return 5;
    if (width >= 1200) return 4;
    if (width >= 850) return 3;
    if (width >= 560) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(visibleSectionsProvider);
    final ranked = ref.watch(rankedTagsProvider);
    final filter = ref.watch(filterProvider);
    final hasAnyEntries = ref.watch(entriesProvider).isNotEmpty;

    final width = MediaQuery.of(context).size.width;
    final columns = _columnsForWidth(width);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 96,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                '👑',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),

          // Filter bar.
          if (ranked.isNotEmpty)
            SliverToBoxAdapter(
              child: _FilterBar(
                ranked: ranked,
                active: filter,
                onToggle: (id) =>
                    ref.read(filterProvider.notifier).toggle(id),
                onClear: () => ref.read(filterProvider.notifier).clear(),
              ),
            ),

          if (sections.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(filtered: hasAnyEntries),
            ),

          for (final section in sections) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.hairline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${section.entries.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childCount: section.entries.length,
                itemBuilder: (context, i) =>
                    EntryCard(entry: section.entries[i]),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/entry/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New entry'),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.ranked,
    required this.active,
    required this.onToggle,
    required this.onClear,
  });

  final List<TagUsage> ranked;
  final Set<String> active;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: ranked.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final u = ranked[i];
                return Center(
                  child: TagChip(
                    name: u.tag.name,
                    count: u.count,
                    selected: active.contains(u.tag.id),
                    onTap: () => onToggle(u.tag.id),
                  ),
                );
              },
            ),
          ),
          if (active.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear'),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered});

  /// True when there are entries but the filter hid them all.
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            filtered ? '🔍' : '✨',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            filtered ? 'No entries match those tags' : 'No entries yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'Try clearing your filters.'
                : 'Tap “New entry” to log your first moment.',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
