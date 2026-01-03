import '../models/car_generation_model.dart';
import '../../../../core/api/endpoints.dart';
import 'package:dio/dio.dart';

class CarGenerationApi {
  final Dio dio;

  CarGenerationApi(this.dio);

  Future<List<CarGenerationModel>> getGenerations({
    required int markId,
    required int modelId,
    String? search,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await dio.get(
      Endpoints.carGenerations.replaceAll('{mark_id}', markId.toString()).replaceAll('{model_id}', modelId.toString()),
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': perPage,
      },
    );

    final List<dynamic> data = response.data['data'];
    return data.map((json) => CarGenerationModel.fromJson(json)).toList();
  }
}
