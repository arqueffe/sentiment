import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sentiment/data/emotion_inference_service.dart';
import 'package:sentiment/data/emotion_label_mapper.dart';
import 'package:sentiment/data/entry_repository.dart';
import 'package:sentiment/state/entry_controller.dart';
import 'package:sentiment/state/sentence_emotion_controller.dart';

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository();
});

final entriesProvider = StreamProvider((ref) {
  return ref.watch(entryRepositoryProvider).watchEntries();
});

final entryControllerProvider = Provider<EntryController>((ref) {
  return EntryController(ref.watch(entryRepositoryProvider));
});

final emotionLabelMapperProvider = Provider<EmotionLabelMapper>((ref) {
  return EmotionLabelMapper();
});

final emotionInferenceServiceProvider = Provider<EmotionInferenceService>((
  ref,
) {
  return EmotionInferenceService(
    labelMapper: ref.watch(emotionLabelMapperProvider),
  );
});

final sentenceEmotionControllerProvider =
    StateNotifierProvider.autoDispose<
      SentenceEmotionController,
      SentenceEmotionState
    >((ref) {
      return SentenceEmotionController(
        inferenceService: ref.watch(emotionInferenceServiceProvider),
        labelMapper: ref.watch(emotionLabelMapperProvider),
      );
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
