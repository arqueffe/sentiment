import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'package:sentiment/data/encryption_service.dart';

class AuthService {
  AuthService({
    required EncryptionService encryption,
    required LocalAuthentication localAuth,
    required FlutterSecureStorage storage,
  }) : _encryption = encryption,
       _localAuth = localAuth,
       _storage = storage;

  static const _biometricEnabledKey = 'biometric_enabled';

  final EncryptionService _encryption;
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _storage;

  Future<bool> hasPassword() => _encryption.hasWrappedKey();

  Future<bool> canUseBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final enabled = await _storage.read(key: _biometricEnabledKey) == 'true';
    final key = await _encryption.readBiometricKey();
    return canCheck && enabled && key != null;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> isBiometricsEnabled() async {
    return await _storage.read(key: _biometricEnabledKey) == 'true';
  }

  Future<List<int>> createPassword(String password) async {
    final masterKey = await _encryption.createPassword(password);
    return masterKey;
  }

  Future<List<int>> unlockWithPassword(String password) async {
    return await _encryption.unlockWithPassword(password);
  }

  Future<List<int>?> unlockWithBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) {
      return null;
    }
    final didAuth = await _localAuth.authenticate(
      localizedReason: 'Unlock your journal',
    );
    if (!didAuth) {
      return null;
    }
    return await _encryption.readBiometricKey();
  }

  Future<void> storeBiometricKey(List<int> masterKey) async {
    await _encryption.storeBiometricKey(Uint8List.fromList(masterKey));
  }

  Future<bool> enableBiometricsWithPrompt(List<int> masterKey) async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) {
      return false;
    }

    final didAuth = await _localAuth.authenticate(
      localizedReason: 'Enable biometric unlock',
    );
    if (!didAuth) {
      return false;
    }

    await _encryption.storeBiometricKey(Uint8List.fromList(masterKey));
    await setBiometricsEnabled(true);
    return true;
  }

  Future<void> disableBiometrics() async {
    await setBiometricsEnabled(false);
    await _encryption.clearBiometricKey();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final masterKey = await _encryption.unlockWithPassword(currentPassword);
    await _encryption.rewrapMasterKey(
      masterKey: masterKey,
      newPassword: newPassword,
    );
    return true;
  }
}
