import 'package:hive_ce_flutter/hive_flutter.dart';

/// Thin wrapper around the two Hive boxes backing the app. On web, Hive stores
/// data in the browser's IndexedDB, so everything is device/browser specific.
class LocalStore {
  static const String entriesBoxName = 'entries';
  static const String tagsBoxName = 'tags';

  late final Box entriesBox;
  late final Box tagsBox;

  /// Call once at startup, before runApp.
  static Future<LocalStore> open() async {
    await Hive.initFlutter();
    final store = LocalStore._();
    store.entriesBox = await Hive.openBox(entriesBoxName);
    store.tagsBox = await Hive.openBox(tagsBoxName);
    return store;
  }

  LocalStore._();
}
