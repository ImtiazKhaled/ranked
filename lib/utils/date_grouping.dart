import 'package:intl/intl.dart';

import '../models/entry.dart';

/// A titled group of entries in the timeline.
class EntrySection {
  final String title;

  /// Sort key: larger = more recent (sections are shown newest-first).
  final int sortKey;
  final List<Entry> entries;

  EntrySection({
    required this.title,
    required this.sortKey,
    required this.entries,
  });
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday (start) of the week containing [d].
DateTime _weekStart(DateTime d) {
  final date = _dateOnly(d);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}

/// Groups entries so that each day of the *current* week that has entries gets
/// its own section (Today / Yesterday / weekday name), while everything older
/// is bundled into "Week of Mon DD – Sun DD" sections. Newest first.
List<EntrySection> groupEntries(List<Entry> entries, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final currentWeekStart = _weekStart(today);

  // Bucket key -> (title, sortKey, entries)
  final Map<String, EntrySection> sections = {};

  final sorted = [...entries]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  for (final entry in sorted) {
    final day = _dateOnly(entry.createdAt);
    String key;
    String title;
    int sortKey;

    if (!day.isBefore(currentWeekStart)) {
      // Within (or after) the current week -> per-day section.
      key = 'day-${day.toIso8601String()}';
      sortKey = day.millisecondsSinceEpoch;
      final diff = today.difference(day).inDays;
      if (diff == 0) {
        title = 'Today';
      } else if (diff == 1) {
        title = 'Yesterday';
      } else if (diff == -1) {
        title = 'Tomorrow';
      } else {
        title = DateFormat('EEEE').format(day); // weekday name
      }
    } else {
      // Older -> weekly bucket.
      final ws = _weekStart(day);
      final we = ws.add(const Duration(days: 6));
      key = 'week-${ws.toIso8601String()}';
      sortKey = ws.millisecondsSinceEpoch;
      final fmt = DateFormat('MMM dd');
      title = 'Week of ${fmt.format(ws)} – ${fmt.format(we)}';
    }

    sections
        .putIfAbsent(
          key,
          () => EntrySection(title: title, sortKey: sortKey, entries: []),
        )
        .entries
        .add(entry);
  }

  final result = sections.values.toList()
    ..sort((a, b) => b.sortKey.compareTo(a.sortKey));
  return result;
}
