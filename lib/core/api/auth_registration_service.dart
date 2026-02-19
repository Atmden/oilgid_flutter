import 'package:oil_gid/core/storage/token_storage.dart';

import 'dio_client.dart';
import 'endpoints.dart';

class AuthRegistrationPayload {
  final String phoneNumber;
  final String name;
  final String password;

  const AuthRegistrationPayload({
    required this.phoneNumber,
    required this.name,
    required this.password,
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
        'phone': payload.phoneNumber,
        'name': payload.name,
        'password': payload.password,
        'password_confirmation': payload.password,
      },
    );
    final body = response.data;
    final responseError = _extractResponseError(body);
    if (responseError != null) {
      throw Exception(responseError);
    }

    final token = _extractUserToken(body);
    if (token == null) {
      throw Exception('Не удалось получить токен пользователя.');
    }

    await _tokenStorage.saveRegisteredPhone(payload.phoneNumber);
    await _tokenStorage.saveUserToken(token);
    await _tokenStorage.setPhoneRegistrationCompleted(true);
  }

  Future<void> loginWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _dio.post(
      Endpoints.login,
      data: {'phone': phoneNumber, 'password': password},
    );

    final body = response.data;
    final responseError = _extractResponseError(body);
    if (responseError != null) {
      throw Exception(responseError);
    }

    final token = _extractUserToken(body);
    if (token == null) {
      throw Exception('Не удалось получить токен пользователя.');
    }

    await _tokenStorage.saveRegisteredPhone(phoneNumber);
    await _tokenStorage.saveUserToken(token);
    await _tokenStorage.setPhoneRegistrationCompleted(true);
  }

  String? _extractResponseError(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) {
            return first.trim();
          }
        }
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    if (data['success'] == false) {
      return 'Не удалось выполнить запрос.';
    }

    return null;
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
