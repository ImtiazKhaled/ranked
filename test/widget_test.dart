import 'package:flutter_test/flutter_test.dart';
import 'package:ranked/data/emotion_wheel_data.dart';
import 'package:ranked/models/entry.dart';
import 'package:ranked/models/tier.dart';
import 'package:ranked/utils/color_from_string.dart';
import 'package:ranked/utils/date_grouping.dart';

Entry _entry(String id, DateTime created) => Entry(
      id: id,
      summary: 's',
      description: '',
      tier: Tier.b,
      emotion: null,
      tagIds: const [],
      imageBytes: null,
      createdAt: created,
      updatedAt: created,
    );

void main() {
  test('emotion wheel has 7 primaries, each 3 tiers deep', () {
    expect(kEmotionWheel.length, 7);
    for (final primary in kEmotionWheel) {
      expect(primary.children, isNotEmpty);
      for (final secondary in primary.children) {
        expect(secondary.children, isNotEmpty);
      }
    }
  });

  test('tag colour is deterministic for a given name', () {
    expect(colorFromString('work'), colorFromString('work'));
  });

  test('grouping: today gets its own section, older bundles by week', () {
    final now = DateTime(2026, 8, 12); // a Wednesday
    final sections = groupEntries([
      _entry('a', now),
      _entry('b', now.subtract(const Duration(days: 20))),
    ], now: now);

    expect(sections.first.title, 'Today');
    expect(sections.last.title, startsWith('Week of'));
  });
}
