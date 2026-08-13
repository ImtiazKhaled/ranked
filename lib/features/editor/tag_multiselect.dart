import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tag.dart';
import '../../providers/providers.dart';
import '../../widgets/tag_chip.dart';

/// Multi-select tag input. Existing tags are suggested in usage-ranked order;
/// typing a name that doesn't exist offers an inline "Create" option.
class TagMultiSelect extends ConsumerStatefulWidget {
  const TagMultiSelect({
    super.key,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  ConsumerState<TagMultiSelect> createState() => _TagMultiSelectState();
}

class _TagMultiSelectState extends ConsumerState<TagMultiSelect> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String id) {
    if (widget.selectedIds.contains(id)) return;
    widget.onChanged([...widget.selectedIds, id]);
  }

  void _remove(String id) {
    widget.onChanged(widget.selectedIds.where((e) => e != id).toList());
  }

  void _createAndAdd(String name) {
    final tag = ref.read(tagsProvider.notifier).createOrGet(name);
    _add(tag.id);
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final ranked = ref.watch(rankedTagsProvider);
    final tagsNotifier = ref.read(tagsProvider.notifier);
    final q = _query.trim().toLowerCase();

    final selectedTags = widget.selectedIds
        .map((id) => tagsNotifier.byId(id))
        .whereType<Tag>()
        .toList();

    final suggestions = ranked
        .where((u) => !widget.selectedIds.contains(u.tag.id))
        .where((u) => q.isEmpty || u.tag.name.toLowerCase().contains(q))
        .toList();

    final exactExists =
        ranked.any((u) => u.tag.name.toLowerCase() == q) || q.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in selectedTags)
                TagChip(
                  name: t.name,
                  selected: true,
                  onRemove: () => _remove(t.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _controller,
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) _createAndAdd(v);
          },
          decoration: const InputDecoration(
            hintText: 'Search or create a tag…',
            prefixIcon: Icon(Icons.local_offer_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (q.isNotEmpty && !exactExists)
              _CreateChip(
                label: _query.trim(),
                onTap: () => _createAndAdd(_query),
              ),
            for (final u in suggestions)
              TagChip(
                name: u.tag.name,
                count: u.count,
                onTap: () => _add(u.tag.id),
              ),
            if (suggestions.isEmpty && (q.isEmpty || exactExists))
              Text(
                q.isEmpty ? 'No tags yet — type to create one.' : 'Already added.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CreateChip extends StatelessWidget {
  const _CreateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 16),
              const SizedBox(width: 4),
              Text(
                'Create "$label"',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
