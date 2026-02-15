import 'package:hive/hive.dart';

import 'package:sentiment/models/entry.dart';

class HiveAdapters {
  static bool _registered = false;

  static void register() {
    if (_registered) {
      return;
    }
    Hive.registerAdapter(EmotionSelectionAdapter());
    Hive.registerAdapter(SentenceEmotionAnnotationAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    _registered = true;
  }
}
