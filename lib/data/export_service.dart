import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

import 'package:sentiment/models/entry.dart';

class ExportService {
  static const _maxImportBytes = 2 * 1024 * 1024;

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

    final size = await file.length();
    if (size > _maxImportBytes) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        return null;
      }
      final map = Map<String, dynamic>.from(decoded);
      final entriesValue = map['entries'];
      if (entriesValue is! List) {
        return null;
      }

      return entriesValue.map((entry) {
        if (entry is! Map) {
          throw const FormatException('Invalid entry structure');
        }
        return JournalEntry.fromJson(Map<String, dynamic>.from(entry));
      }).toList();
    } on FormatException {
      return null;
    }
  }
}
