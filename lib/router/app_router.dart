import 'package:flutter/material.dart';

import 'package:sentiment/models/entry.dart';
import 'package:sentiment/ui/entry_detail_screen.dart';
import 'package:sentiment/ui/entry_editor_screen.dart';
import 'package:sentiment/ui/home_screen.dart';
import 'package:sentiment/ui/settings_screen.dart';

class AppRouter {
  static const home = '/home';
  static const newEntry = '/entry/new';
  static const entryDetail = '/entry/detail';
  static const settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case newEntry:
        return MaterialPageRoute(builder: (_) => const EntryEditorScreen());
      case entryDetail:
        final entry = settings.arguments as JournalEntry;
        return MaterialPageRoute(
          builder: (_) => EntryDetailScreen(entry: entry),
        );
      case AppRouter.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
