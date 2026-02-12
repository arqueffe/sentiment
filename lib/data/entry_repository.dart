import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import 'package:sentiment/data/hive_adapters.dart';
import 'package:sentiment/models/entry.dart';

class EntryRepository {
  EntryRepository();

  static const _boxName = 'entries';

  Box<JournalEntry>? _box;
  final Completer<void> _openCompleter = Completer<void>();

  Future<void> open(Uint8List encryptionKey) async {
    if (_box?.isOpen ?? false) {
      return;
    }
    HiveAdapters.register();
    _box = await Hive.openBox<JournalEntry>(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    if (!_openCompleter.isCompleted) {
      _openCompleter.complete();
    }
  }

  bool get isOpen => _box?.isOpen ?? false;

  Stream<List<JournalEntry>> watchEntries() async* {
    await _openCompleter.future;
    yield _sorted(_box!.values.toList());
    yield* _box!.watch().map((_) => _sorted(_box!.values.toList()));
  }

  Future<void> addEntry(JournalEntry entry) async {
    await _openCompleter.future;
    await _box?.put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _openCompleter.future;
    await _box?.delete(id);
  }

  Future<void> upsertEntries(Iterable<JournalEntry> entries) async {
    await _openCompleter.future;
    final map = {for (final entry in entries) entry.id: entry};
    await _box?.putAll(map);
  }

  List<JournalEntry> _sorted(List<JournalEntry> entries) {
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }
}
