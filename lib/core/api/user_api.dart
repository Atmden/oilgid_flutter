import 'package:oil_gid/core/storage/token_storage.dart';

import 'dio_client.dart';
import 'endpoints.dart';

class UserApi {
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(Endpoints.profile);
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Некорректный ответ сервера.');
    }

    if (body['success'] == false) {
      throw Exception(_extractMessage(body, 'Не удалось получить профиль.'));
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Данные профиля отсутствуют в ответе сервера.');
  }

  Future<void> login(String email, String password) async {
    final response = await _dio.post(
      Endpoints.login,
      data: {'email': email, 'password': password},
    );

    await TokenStorage().saveUserToken(response.data['token']);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    String? birthDate,
  }) async {
    final response = await _dio.patch(
      Endpoints.profile,
      data: {
        'name': name,
        'email': email,
        'birth_date': birthDate,
      },
    );
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Некорректный ответ сервера.');
    }

    if (body['success'] == false) {
      throw Exception(_extractMessage(body, 'Не удалось обновить профиль.'));
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Данные профиля отсутствуют в ответе сервера.');
  }

  String _extractMessage(Map<String, dynamic> body, String fallback) {
    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final errors = body['errors'];
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

    return fallback;
  }
}
