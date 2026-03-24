import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sentiment/state/providers.dart';
import 'package:sentiment/ui/home_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  static const _demoEncryptionKey = <int>[
    0x9A,
    0x4D,
    0x6E,
    0x21,
    0x4F,
    0x98,
    0x10,
    0xAD,
    0x27,
    0x31,
    0x5B,
    0xC0,
    0x76,
    0x18,
    0xE3,
    0x44,
    0x55,
    0x26,
    0xB9,
    0xAF,
    0x39,
    0xD4,
    0x80,
    0x11,
    0x72,
    0x63,
    0xA8,
    0xC7,
    0x95,
    0x0E,
    0x14,
    0x2B,
  ];

  Future<void>? _openFuture;

  @override
  void initState() {
    super.initState();
    final key = Uint8List.fromList(_demoEncryptionKey);
    _openFuture = ref.read(entryRepositoryProvider).open(key);
  }

  @override
  Widget build(BuildContext context) {
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
