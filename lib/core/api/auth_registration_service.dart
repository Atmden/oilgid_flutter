import 'package:oil_gid/core/storage/token_storage.dart';

import 'dio_client.dart';
import 'endpoints.dart';

class AuthRegistrationPayload {
  final String phoneNumber;
  final String name;
  final String password;
  final String passwordHash;
  final String pin;
  final String pinHash;

  const AuthRegistrationPayload({
    required this.phoneNumber,
    required this.name,
    required this.password,
    required this.passwordHash,
    required this.pin,
    required this.pinHash,
  });
}

class AuthRegistrationService {
  final TokenStorage _tokenStorage;
  final _dio = DioClient().dio;

  AuthRegistrationService({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<void> completeRegistration(AuthRegistrationPayload payload) async {
    final response = await _dio.post(
      Endpoints.register,
      data: {
        'user_phone': payload.phoneNumber,
        'name': payload.name,
        'password': payload.password,
        'pin': payload.pin,
      },
    );

    final token = _extractUserToken(response.data);
    if (token == null) {
      throw Exception('Не удалось получить токен пользователя.');
    }

    await _tokenStorage.saveRegisteredPhone(payload.phoneNumber);
    await _tokenStorage.savePasswordHash(payload.passwordHash);
    await _tokenStorage.savePinHash(payload.pinHash);
    await _tokenStorage.saveUserToken(token);
    await _tokenStorage.setPhoneRegistrationCompleted(true);
  }

  String? _extractUserToken(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['user_token'] is String) {
        return data['user_token'] as String;
      }
      if (data['token'] is String) {
        return data['token'] as String;
      }
      if (data['data'] is Map<String, dynamic>) {
        final nested = data['data'] as Map<String, dynamic>;
        if (nested['user_token'] is String) {
          return nested['user_token'] as String;
        }
        if (nested['token'] is String) {
          return nested['token'] as String;
        }
      }
    }
    return null;
  }
}
