import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sentiment/state/auth_controller.dart';
import 'package:sentiment/state/providers.dart';
import 'package:sentiment/ui/unlock_screen.dart';
import 'package:sentiment/ui/home_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  Future<void>? _openFuture;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(authControllerProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    switch (auth.status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.locked:
        return const UnlockScreen();
      case AuthStatus.unlocked:
        final key = ref.read(authControllerProvider.notifier).masterKey;
        if (key == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        _openFuture ??= ref.read(entryRepositoryProvider).open(key);
        return FutureBuilder<void>(
          future: _openFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const HomeScreen();
          },
        );
    }
  }
}
