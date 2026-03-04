import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import 'package:sentiment/data/hive_adapters.dart';
import 'package:sentiment/models/entry.dart';

class EntryRepository {
  EntryRepository();

  static const _boxName = 'entries';

  Box<JournalEntry>? _box;
  Completer<void> _openCompleter = Completer<void>();
  Future<void>? _openingFuture;
  Future<void>? _closingFuture;

  Future<void> open(Uint8List encryptionKey) async {
    final closingFuture = _closingFuture;
    if (closingFuture != null) {
      await closingFuture;
    }
    if (_box?.isOpen ?? false) {
      return;
    }
    final openingFuture = _openingFuture ??= _doOpen(encryptionKey);
    await openingFuture;
  }

  Future<void> _doOpen(Uint8List encryptionKey) async {
    try {
      HiveAdapters.register();
      _box = await Hive.openBox<JournalEntry>(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      if (!_openCompleter.isCompleted) {
        _openCompleter.complete();
      }
    } finally {
      _openingFuture = null;
    }
  }

  bool get isOpen => _box?.isOpen ?? false;

  Stream<List<JournalEntry>> watchEntries() async* {
    await _openCompleter.future;
    final box = _requireOpenBox();
    yield _sorted(box.values.toList());
    yield* box.watch().map((_) => _sorted(box.values.toList()));
  }

  Future<void> addEntry(JournalEntry entry) async {
    await _openCompleter.future;
    await _requireOpenBox().put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _openCompleter.future;
    await _requireOpenBox().delete(id);
  }

  Future<void> upsertEntries(Iterable<JournalEntry> entries) async {
    await _openCompleter.future;
    final map = {for (final entry in entries) entry.id: entry};
    await _requireOpenBox().putAll(map);
  }

  Future<void> close() async {
    if (_box == null && _openingFuture == null) {
      return;
    }
    final closingFuture = _closeInternal();
    _closingFuture = closingFuture;
    await closingFuture;
    if (identical(_closingFuture, closingFuture)) {
      _closingFuture = null;
    }
  }

  Future<void> _closeInternal() async {
    final openingFuture = _openingFuture;
    if (openingFuture != null) {
      await openingFuture;
    }

    final box = _box;
    _box = null;
    _openCompleter = Completer<void>();

    if (box?.isOpen ?? false) {
      await box!.close();
    }
  }

  Box<JournalEntry> _requireOpenBox() {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('Entries box is not open.');
    }
    return box;
  }

  List<JournalEntry> _sorted(List<JournalEntry> entries) {
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }
}
