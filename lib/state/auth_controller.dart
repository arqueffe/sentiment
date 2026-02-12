import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sentiment/data/auth_service.dart';
import 'package:sentiment/data/encryption_service.dart';

enum AuthStatus { loading, locked, unlocked }

class AuthState {
  const AuthState({
    required this.status,
    required this.hasPassword,
    required this.canBiometric,
  });

  final AuthStatus status;
  final bool hasPassword;
  final bool canBiometric;

  AuthState copyWith({
    AuthStatus? status,
    bool? hasPassword,
    bool? canBiometric,
  }) {
    return AuthState(
      status: status ?? this.status,
      hasPassword: hasPassword ?? this.hasPassword,
      canBiometric: canBiometric ?? this.canBiometric,
    );
  }

  static const initial = AuthState(
    status: AuthStatus.loading,
    hasPassword: false,
    canBiometric: false,
  );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthService authService,
    required EncryptionService encryptionService,
  }) : _authService = authService,
       _encryption = encryptionService,
       super(AuthState.initial);

  final AuthService _authService;
  final EncryptionService _encryption;
  Uint8List? _masterKey;

  Uint8List? get masterKey => _masterKey;

  Future<void> initialize() async {
    final hasPassword = await _authService.hasPassword();
    final canBiometric = await _authService.canUseBiometrics();
    state = state.copyWith(
      status: AuthStatus.locked,
      hasPassword: hasPassword,
      canBiometric: canBiometric,
    );
  }

  Future<void> createPassword(
    String password, {
    required bool enableBiometric,
  }) async {
    _masterKey = Uint8List.fromList(
      await _authService.createPassword(password),
    );
    if (enableBiometric) {
      await _authService.setBiometricsEnabled(true);
      await _authService.storeBiometricKey(_masterKey!);
    } else {
      await _authService.setBiometricsEnabled(false);
      await _encryption.clearBiometricKey();
    }
    final canBiometric = await _authService.canUseBiometrics();
    state = state.copyWith(
      status: AuthStatus.unlocked,
      hasPassword: true,
      canBiometric: canBiometric,
    );
  }

  Future<bool> unlockWithPassword(
    String password, {
    bool? enableBiometric,
  }) async {
    try {
      _masterKey = Uint8List.fromList(
        await _authService.unlockWithPassword(password),
      );
      if (enableBiometric == true) {
        await _authService.setBiometricsEnabled(true);
        await _authService.storeBiometricKey(_masterKey!);
      } else if (enableBiometric == false) {
        await _authService.setBiometricsEnabled(false);
        await _encryption.clearBiometricKey();
      }
      final canBiometric = await _authService.canUseBiometrics();
      state = state.copyWith(
        status: AuthStatus.unlocked,
        canBiometric: canBiometric,
      );
      return true;
    } on EncryptionException {
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    final key = await _authService.unlockWithBiometrics();
    if (key == null) {
      return false;
    }
    _masterKey = Uint8List.fromList(key);
    state = state.copyWith(status: AuthStatus.unlocked);
    return true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.trim().isEmpty) {
      return false;
    }

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _masterKey = Uint8List.fromList(
        await _authService.unlockWithPassword(newPassword),
      );
      return true;
    } on EncryptionException {
      return false;
    }
  }

  Future<bool> enableBiometricWithPrompt() async {
    final key = _masterKey;
    if (key == null) {
      return false;
    }
    final enabled = await _authService.enableBiometricsWithPrompt(key);
    final canBiometric = await _authService.canUseBiometrics();
    state = state.copyWith(canBiometric: canBiometric);
    return enabled;
  }

  Future<void> disableBiometric() async {
    await _authService.disableBiometrics();
    final canBiometric = await _authService.canUseBiometrics();
    state = state.copyWith(canBiometric: canBiometric);
  }
}
