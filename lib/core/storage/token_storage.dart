import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _userTokenKey = 'user_token';
  static const _appTokenKey = 'app_token';
  static const _passwordHashKey = 'password_hash';
  static const _pinHashKey = 'pin_hash';
  static const _registeredPhoneKey = 'registered_phone';
  static const _phoneRegistrationCompletedKey = 'phone_registration_completed';
  static const _userProfileKey = 'user_profile';

  final _storage = const FlutterSecureStorage();

  Future<void> saveUserToken(String token) async {
    await _storage.write(key: _userTokenKey, value: token);
  }

  Future<void> saveAppToken(String token) async {
    await _storage.write(key: _appTokenKey, value: token);
  }

  Future<String?> getUserToken() async {
    return _storage.read(key: _userTokenKey);
  }

  Future<String?> getAppToken() async {
    return _storage.read(key: _appTokenKey);
  }

  Future<void> clearUser() async {
    await _storage.delete(key: _userTokenKey);
    await _storage.delete(key: _userProfileKey);
  }

  Future<void> savePasswordHash(String hash) async {
    await _storage.write(key: _passwordHashKey, value: hash);
  }

  Future<String?> getPasswordHash() async {
    return _storage.read(key: _passwordHashKey);
  }

  Future<void> savePinHash(String hash) async {
    await _storage.write(key: _pinHashKey, value: hash);
  }

  Future<String?> getPinHash() async {
    return _storage.read(key: _pinHashKey);
  }

  Future<void> saveRegisteredPhone(String phone) async {
    await _storage.write(key: _registeredPhoneKey, value: phone);
  }

  Future<String?> getRegisteredPhone() async {
    return _storage.read(key: _registeredPhoneKey);
  }

  Future<void> setPhoneRegistrationCompleted(bool value) async {
    await _storage.write(
      key: _phoneRegistrationCompletedKey,
      value: value ? 'true' : 'false',
    );
  }

  Future<bool> isPhoneRegistrationCompleted() async {
    return (await _storage.read(key: _phoneRegistrationCompletedKey)) == 'true';
  }

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await _storage.write(key: _userProfileKey, value: jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final raw = await _storage.read(key: _userProfileKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> clearUserProfile() async {
    await _storage.delete(key: _userProfileKey);
  }

  Future<void> clearPhoneRegistrationData() async {
    await _storage.delete(key: _passwordHashKey);
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _registeredPhoneKey);
    await _storage.delete(key: _phoneRegistrationCompletedKey);
    await _storage.delete(key: _userTokenKey);
    await _storage.delete(key: _userProfileKey);
  }
}
