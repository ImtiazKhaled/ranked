/// A user-created tag. Colour is derived deterministically from the name
/// (see utils/color_from_string.dart), so it is not persisted. Usage count is
/// computed live from entries, so it is not persisted either.
class Tag {
  final String id;
  final String name;

  const Tag({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  static Tag fromMap(Map map) => Tag(
        id: map['id'] as String,
        name: map['name'] as String,
      );
}
