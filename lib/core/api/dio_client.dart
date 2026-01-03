import 'package:dio/dio.dart';
import 'package:oil_gid/core/api/endpoints.dart';
import 'package:oil_gid/core/storage/token_storage.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  final TokenStorage _tokenStorage = TokenStorage();

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
        validateStatus: (_) => true,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final userToken = await _tokenStorage.getUserToken();
          final appToken = await _tokenStorage.getAppToken();

          if (userToken != null) {
            options.headers['Authorization'] = 'Bearer $userToken';
          } else if (appToken != null) {
            options.headers['Authorization'] = 'Bearer $appToken';
          }

          handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) {
            // TODO: logout / refresh token
          }
          return handler.next(e);
        },
      ),
    );
  }
}
