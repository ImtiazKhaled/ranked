import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../data/local_store.dart';
import '../models/entry.dart';
import '../models/tag.dart';
import '../utils/date_grouping.dart';

const _uuid = Uuid();

/// Holds the opened [LocalStore]. Overridden in main() after boxes are opened.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);

// ---------------------------------------------------------------------------
// Entries
// ---------------------------------------------------------------------------

class EntriesNotifier extends StateNotifier<List<Entry>> {
  EntriesNotifier(this._box) : super(_readAll(_box));

  final Box _box;

  static List<Entry> _readAll(Box box) =>
      box.values.map((e) => Entry.fromMap(Map<String, dynamic>.from(e))).toList();

  void add(Entry entry) {
    _box.put(entry.id, entry.toMap());
    state = [...state, entry];
  }

  void update(Entry entry) {
    _box.put(entry.id, entry.toMap());
    state = [for (final e in state) e.id == entry.id ? entry : e];
  }

  void delete(String id) {
    _box.delete(id);
    state = state.where((e) => e.id != id).toList();
  }

  Entry? byId(String id) {
    for (final e in state) {
      if (e.id == id) return e;
    }
    return null;
  }
}

final entriesProvider =
    StateNotifierProvider<EntriesNotifier, List<Entry>>((ref) {
  return EntriesNotifier(ref.watch(localStoreProvider).entriesBox);
});

final entryByIdProvider = Provider.family<Entry?, String>((ref, id) {
  final entries = ref.watch(entriesProvider);
  for (final e in entries) {
    if (e.id == id) return e;
  }
  return null;
});

// ---------------------------------------------------------------------------
// Tags
// ---------------------------------------------------------------------------

class TagsNotifier extends StateNotifier<List<Tag>> {
  TagsNotifier(this._box)
      : super(_box.values
            .map((e) => Tag.fromMap(Map<String, dynamic>.from(e)))
            .toList());

  final Box _box;

  /// Returns an existing tag (case-insensitive) or creates a new one.
  Tag createOrGet(String rawName) {
    final name = rawName.trim();
    for (final t in state) {
      if (t.name.toLowerCase() == name.toLowerCase()) return t;
    }
    final tag = Tag(id: _uuid.v4(), name: name);
    _box.put(tag.id, tag.toMap());
    state = [...state, tag];
    return tag;
  }

  Tag? byId(String id) {
    for (final t in state) {
      if (t.id == id) return t;
    }
    return null;
  }
}

final tagsProvider = StateNotifierProvider<TagsNotifier, List<Tag>>((ref) {
  return TagsNotifier(ref.watch(localStoreProvider).tagsBox);
});

/// A tag paired with how many entries currently use it.
class TagUsage {
  final Tag tag;
  final int count;
  const TagUsage(this.tag, this.count);
}

/// All tags ranked by usage (most-used first, ties broken alphabetically).
final rankedTagsProvider = Provider<List<TagUsage>>((ref) {
  final tags = ref.watch(tagsProvider);
  final entries = ref.watch(entriesProvider);

  final counts = <String, int>{};
  for (final e in entries) {
    for (final id in e.tagIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }

  final list =
      tags.map((t) => TagUsage(t, counts[t.id] ?? 0)).toList(growable: false);
  list.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    return a.tag.name.toLowerCase().compareTo(b.tag.name.toLowerCase());
  });
  return list;
});

// ---------------------------------------------------------------------------
// Filtering + grouped timeline
// ---------------------------------------------------------------------------

class FilterNotifier extends StateNotifier<Set<String>> {
  FilterNotifier() : super(const {});

  void toggle(String tagId) {
    final next = {...state};
    if (!next.remove(tagId)) next.add(tagId);
    state = next;
  }

  void clear() => state = const {};
}

/// Active tag-id filter set. Empty = show everything.
final filterProvider =
    StateNotifierProvider<FilterNotifier, Set<String>>((ref) => FilterNotifier());

/// Entries after applying the active tag filter (OR semantics), grouped into
/// timeline sections.
final visibleSectionsProvider = Provider<List<EntrySection>>((ref) {
  final entries = ref.watch(entriesProvider);
  final filter = ref.watch(filterProvider);

  final filtered = filter.isEmpty
      ? entries
      : entries.where((e) => e.tagIds.any(filter.contains)).toList();

  return groupEntries(filtered);
});
