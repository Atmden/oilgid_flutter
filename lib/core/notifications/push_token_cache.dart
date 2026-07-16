import 'package:shared_preferences/shared_preferences.dart';

class PushTokenCache {
  static const _lastRegisteredTokenKey = 'fcm_last_registered_token';

  Future<String?> getLastRegisteredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastRegisteredTokenKey);
  }

  Future<void> saveLastRegisteredToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRegisteredTokenKey, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastRegisteredTokenKey);
  }
}
