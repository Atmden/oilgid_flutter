import 'package:oil_gid/core/storage/token_storage.dart';

import 'dio_client.dart';
import 'endpoints.dart';

class UserApi {
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(Endpoints.profile);
    return response.data;
  }

  Future<void> login(String email, String password) async {
    final response = await _dio.post(
      Endpoints.login,
      data: {'email': email, 'password': password},
    );

    await TokenStorage().saveUserToken(response.data['token']);
  }
}
