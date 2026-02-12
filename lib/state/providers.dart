import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sentiment/data/auth_service.dart';
import 'package:sentiment/data/encryption_service.dart';
import 'package:sentiment/data/entry_repository.dart';
import 'package:sentiment/data/export_service.dart';
import 'package:sentiment/state/auth_controller.dart';
import 'package:sentiment/state/entry_controller.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService(storage: ref.watch(secureStorageProvider));
});

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    encryption: ref.watch(encryptionServiceProvider),
    localAuth: ref.watch(localAuthProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      authService: ref.watch(authServiceProvider),
      encryptionService: ref.watch(encryptionServiceProvider),
    );
  },
);

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository();
});

final entriesProvider = StreamProvider((ref) {
  return ref.watch(entryRepositoryProvider).watchEntries();
});

final entryControllerProvider = Provider<EntryController>((ref) {
  return EntryController(ref.watch(entryRepositoryProvider));
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    final controller = ThemeModeController();
    unawaited(controller.load());
    return controller;
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system);

  static const _themeModeKey = 'app_theme_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_themeModeKey);
    if (mode == 'dark') {
      state = ThemeMode.dark;
      return;
    }
    if (mode == 'light') {
      state = ThemeMode.light;
      return;
    }
    state = ThemeMode.system;
  }

  Future<void> setDarkMode(bool enabled) async {
    state = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, enabled ? 'dark' : 'light');
  }
}
