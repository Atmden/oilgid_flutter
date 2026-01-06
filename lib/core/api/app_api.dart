import 'package:oil_gid/core/api/init_token_generator.dart';
import 'package:oil_gid/core/storage/token_storage.dart';

import '../../features/car_marks/data/datasources/car_mark_api.dart';
import '../../features/car_models/data/datasources/car_model_api.dart';
import '../../features/car_generations/data/datasources/car_generation_api.dart';
import '../../features/car_configurations/data/datasources/car_configuration_api.dart';
import '../../features/car_modifications/data/datasources/car_modification_api.dart';
import 'dio_client.dart';
import 'endpoints.dart';

class AppApi {
  final _dio = DioClient().dio;

  late final CarMarkApi carMarkApi = CarMarkApi(_dio);
  late final CarModelApi carModelApi = CarModelApi(_dio);
  late final CarGenerationApi carGenerationApi = CarGenerationApi(_dio);
  late final CarConfigurationApi carConfigurationApi = CarConfigurationApi(
    _dio,
  );
  late final CarModificationApi carModificationApi = CarModificationApi(_dio);
  Future<Map<String, dynamic>> getConfig() async {
    final response = await _dio.get(Endpoints.appConfig);
    return response.data;
  }

  Future<void> initApp() async {
    final appToken = await TokenStorage().getAppToken();
    if (appToken == null) {
      final data = await InitTokenGenerator.generate();
      final response = await _dio.post(Endpoints.appInit, data: data);
      print(response.data);
      final appToken = response.data['token'];
      await TokenStorage().saveAppToken(appToken);
    }
  }

  Future<String> getPrivacyPolicy() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/app/privacy-policy',
    );

    print(response.data);

    return response.data?['data'] as String? ?? '';
  }
}
