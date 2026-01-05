import '../models/car_configuration_model.dart';
import '../../../../core/api/endpoints.dart';
import 'package:dio/dio.dart';

class CarConfigurationApi {
  final Dio dio;

  CarConfigurationApi(this.dio);

  Future<List<CarConfigurationModel>> getConfigurations({
    required int markId,
    required int modelId,
    required int generationId,
    String? search,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await dio.get(
      Endpoints.carConfigurations
          .replaceAll('{mark_id}', markId.toString())
          .replaceAll('{model_id}', modelId.toString())
          .replaceAll('{generation_id}', generationId.toString()),
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': perPage,
      },
    );
    print(response);

    final List<dynamic> data = response.data['data'];
    return data.map((json) => CarConfigurationModel.fromJson(json)).toList();
  }
}
