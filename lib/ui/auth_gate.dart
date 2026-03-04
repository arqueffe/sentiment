import 'dart:async';

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
  static const _relockGracePeriod = Duration(seconds: 60);

  Future<void>? _openFuture;
  DateTime? _backgroundedAt;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _AuthGateLifecycleObserver(onStateChanged: _onLifecycleChanged);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    Future<void>.microtask(
      () => ref.read(authControllerProvider.notifier).initialize(),
    );
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    final controller = ref.read(authControllerProvider.notifier);
    final auth = ref.read(authControllerProvider);

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (auth.status == AuthStatus.unlocked) {
          _backgroundedAt ??= DateTime.now();
        }
        break;
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (backgroundedAt == null || auth.status != AuthStatus.unlocked) {
          return;
        }
        final elapsed = DateTime.now().difference(backgroundedAt);
        if (elapsed >= _relockGracePeriod) {
          controller.lock();
        }
        break;
      case AppLifecycleState.detached:
        if (auth.status == AuthStatus.unlocked) {
          controller.lock();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    switch (auth.status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.locked:
        if (_openFuture != null) {
          _openFuture = null;
          unawaited(ref.read(entryRepositoryProvider).close());
        }
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

class _AuthGateLifecycleObserver extends WidgetsBindingObserver {
  _AuthGateLifecycleObserver({required this.onStateChanged});

  final void Function(AppLifecycleState state) onStateChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
