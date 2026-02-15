import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

import 'package:sentiment/models/entry.dart';

class ExportService {
  Future<void> exportJson(List<JournalEntry> entries) async {
    final json = jsonEncode({
      'version': 2,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    });

    final directory = await getDirectoryPath();
    if (directory == null) {
      return;
    }
    final separator = Platform.pathSeparator;
    final path = '$directory${separator}sentiment_export.json';
    final file = XFile.fromData(
      utf8.encode(json),
      name: 'sentiment_export.json',
      mimeType: 'application/json',
    );
    await file.saveTo(path);
  }

  Future<List<JournalEntry>?> importJson() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null) {
      return null;
    }
    final content = await file.readAsString();
    final map = jsonDecode(content) as Map<String, dynamic>;
    final items = map['entries'] as List<dynamic>;
    return items
        .map((entry) => JournalEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
  }
}
