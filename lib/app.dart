import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sentiment/router/app_router.dart';
import 'package:sentiment/state/providers.dart';
import 'package:sentiment/theme/app_theme.dart';
import 'package:sentiment/ui/auth_gate.dart';

class SentimentApp extends ConsumerWidget {
  const SentimentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Sentiment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const AuthGate(),
    );
  }
}
