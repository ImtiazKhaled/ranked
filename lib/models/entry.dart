import 'dart:typed_data';

import 'emotion.dart';
import 'tier.dart';

/// A single logged "score" of a moment.
class Entry {
  final String id;
  final String summary;
  final String description;
  final Tier tier;
  final EmotionRef? emotion;
  final List<String> tagIds;
  final Uint8List? imageBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Entry({
    required this.id,
    required this.summary,
    required this.description,
    required this.tier,
    required this.emotion,
    required this.tagIds,
    required this.imageBytes,
    required this.createdAt,
    required this.updatedAt,
  });

  Entry copyWith({
    String? summary,
    String? description,
    Tier? tier,
    EmotionRef? emotion,
    bool clearEmotion = false,
    List<String>? tagIds,
    Uint8List? imageBytes,
    bool clearImage = false,
    DateTime? updatedAt,
  }) {
    return Entry(
      id: id,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      tier: tier ?? this.tier,
      emotion: clearEmotion ? null : (emotion ?? this.emotion),
      tagIds: tagIds ?? this.tagIds,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'summary': summary,
        'description': description,
        'tier': tier.label,
        'emotion': emotion?.toMap(),
        'tagIds': tagIds,
        'imageBytes': imageBytes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Entry fromMap(Map map) => Entry(
        id: map['id'] as String,
        summary: map['summary'] as String? ?? '',
        description: map['description'] as String? ?? '',
        tier: Tier.fromLabel(map['tier'] as String? ?? 'C'),
        emotion: EmotionRef.fromMap(map['emotion'] as Map?),
        tagIds: (map['tagIds'] as List?)?.cast<String>() ?? const [],
        imageBytes: map['imageBytes'] as Uint8List?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
