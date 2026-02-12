import 'package:sentiment/data/entry_repository.dart';
import 'package:sentiment/models/entry.dart';

class EntryController {
  EntryController(this._repository);

  final EntryRepository _repository;

  Future<void> addEntry(JournalEntry entry) async {
    await _repository.addEntry(entry);
  }

  Future<void> deleteEntry(String id) async {
    await _repository.deleteEntry(id);
  }

  Future<void> upsertEntries(List<JournalEntry> entries) async {
    await _repository.upsertEntries(entries);
  }
}
