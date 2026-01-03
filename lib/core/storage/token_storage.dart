import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _userTokenKey = 'user_token';
  static const _appTokenKey = 'app_token';

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
  }
}
