import 'dio_client.dart';
import 'endpoints.dart';

class AuthApi {
  final _dio = DioClient().dio;

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
    }
    return fallback;
  }
}
