import '../models/car_model_model.dart';
import '../../../../core/api/endpoints.dart';
import 'package:dio/dio.dart';

class CarModelApi {
  final Dio dio;

  CarModelApi(this.dio);

  Future<List<CarModelModel>> getModels({
    required int markId,
    String? search,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await dio.get(
      Endpoints.carModels.replaceAll('{mark_id}', markId.toString()),
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': perPage,
      },
    );

    final List<dynamic> data = response.data['data'];
    return data.map((json) => CarModelModel.fromJson(json)).toList();
  }
}
