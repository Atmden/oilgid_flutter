import 'dio_client.dart';
import 'endpoints.dart';

class AuthApi {
  final _dio = DioClient().dio;

  Future<bool> checkUserByPhone(String phone) async {
    final response = await _dio.post(
      Endpoints.authCheckUserByPhone,
      data: {'phone': phone},
    );

    if (!_isSuccessResponse(response.data)) {
      throw Exception(
        _extractMessage(
          response.data,
          'Не удалось проверить существование пользователя.',
        ),
      );
    }

    final body = response.data;
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      final data = body['data'] as Map<String, dynamic>;
      return data['exists'] == true;
    }

    throw Exception('Некорректный ответ сервера при проверке пользователя.');
  }

  Future<void> sendCode(String phone) async {
    final response = await _dio.post(
      Endpoints.verifySendCode,
      data: {'user_phone': phone},
    );

    if (!_isSuccessResponse(response.data)) {
      throw Exception(_extractMessage(response.data, 'Не удалось отправить код.'));
    }
  }

  Future<bool> verifyCode({required String phone, required String code}) async {
    final response = await _dio.post(
      Endpoints.verifyCode,
      data: {'user_phone': phone, 'code': code},
    );

    if (!_isSuccessResponse(response.data)) {
      throw Exception(_extractMessage(response.data, 'Не удалось проверить код.'));
    }

    return response.data is Map<String, dynamic> &&
        response.data['data'] is Map<String, dynamic> &&
        response.data['data']['result'] == true;
  }

  Future<void> resetPassword({
    required String phone,
    required String code,
    required String password,
  }) async {
    final response = await _dio.post(
      Endpoints.authResetPassword,
      data: {
        'phone': phone,
        'code': code,
        'password': password,
        'password_confirmation': password,
      },
    );

    if (!_isSuccessResponse(response.data)) {
      throw Exception(
        _extractMessage(response.data, 'Не удалось восстановить пароль.'),
      );
    }
  }

  bool _isSuccessResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['success'] == true;
    }
    return false;
  }

  String _extractMessage(dynamic data, String fallback) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String && first.trim().isNotEmpty) {
              return first;
            }
          }
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
    }
    return fallback;
  }
}
