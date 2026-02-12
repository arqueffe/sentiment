import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  EncryptionService({required FlutterSecureStorage storage})
    : _storage = storage;

  static const _keySalt = 'enc_salt';
  static const _keyNonce = 'enc_nonce';
  static const _keyCipher = 'enc_cipher';
  static const _keyMac = 'enc_mac';
  static const _keyBiometric = 'enc_biometric';

  final FlutterSecureStorage _storage;
  final AesGcm _cipher = AesGcm.with256bits();
  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 150000,
    bits: 256,
  );

  Future<bool> hasWrappedKey() async {
    final salt = await _storage.read(key: _keySalt);
    final cipher = await _storage.read(key: _keyCipher);
    return salt != null && cipher != null;
  }

  Future<Uint8List> createPassword(String password) async {
    final masterKey = _randomBytes(32);
    final salt = _randomBytes(16);
    final keyBytes = await _deriveKey(password, salt);
    final nonce = _randomBytes(12);
    final box = await _cipher.encrypt(
      masterKey,
      secretKey: SecretKey(keyBytes),
      nonce: nonce,
    );

    await _storage.write(key: _keySalt, value: base64Encode(salt));
    await _storage.write(key: _keyNonce, value: base64Encode(nonce));
    await _storage.write(key: _keyCipher, value: base64Encode(box.cipherText));
    await _storage.write(key: _keyMac, value: base64Encode(box.mac.bytes));

    return Uint8List.fromList(masterKey);
  }

  Future<Uint8List> unlockWithPassword(String password) async {
    final salt = await _readBytes(_keySalt);
    final nonce = await _readBytes(_keyNonce);
    final cipherText = await _readBytes(_keyCipher);
    final mac = await _readBytes(_keyMac);

    if (salt == null || nonce == null || cipherText == null || mac == null) {
      throw const EncryptionException('Missing encryption metadata');
    }

    final keyBytes = await _deriveKey(password, salt);
    try {
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
      final clear = await _cipher.decrypt(
        secretBox,
        secretKey: SecretKey(keyBytes),
      );
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw const EncryptionException('Invalid password');
    }
  }

  Future<void> rewrapMasterKey({
    required Uint8List masterKey,
    required String newPassword,
  }) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final keyBytes = await _deriveKey(newPassword, salt);
    final box = await _cipher.encrypt(
      masterKey,
      secretKey: SecretKey(keyBytes),
      nonce: nonce,
    );

    await _storage.write(key: _keySalt, value: base64Encode(salt));
    await _storage.write(key: _keyNonce, value: base64Encode(nonce));
    await _storage.write(key: _keyCipher, value: base64Encode(box.cipherText));
    await _storage.write(key: _keyMac, value: base64Encode(box.mac.bytes));
  }

  Future<void> storeBiometricKey(Uint8List masterKey) async {
    await _storage.write(key: _keyBiometric, value: base64Encode(masterKey));
  }

  Future<Uint8List?> readBiometricKey() async {
    final data = await _storage.read(key: _keyBiometric);
    if (data == null) {
      return null;
    }
    return Uint8List.fromList(base64Decode(data));
  }

  Future<void> clearBiometricKey() async {
    await _storage.delete(key: _keyBiometric);
  }

  Future<Uint8List?> _readBytes(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) {
      return null;
    }
    return Uint8List.fromList(base64Decode(value));
  }

  Future<List<int>> _deriveKey(String password, List<int> salt) async {
    final secretKey = await _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return secretKey.extractBytes();
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}

class EncryptionException implements Exception {
  const EncryptionException(this.message);

  final String message;

  @override
  String toString() => message;
}
