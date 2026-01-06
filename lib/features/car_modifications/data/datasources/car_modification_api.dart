import '../models/car_modification_model.dart';
import '../../../../core/api/endpoints.dart';
import 'package:dio/dio.dart';

class CarModificationApi {
  final Dio dio;

  CarModificationApi(this.dio);

  Future<List<CarModificationModel>> getModifications({
    required int markId,
    required int modelId,
    required int generationId,
    required int configurationId,
    String? search,
    int page = 1,
    int perPage = 25,
  }) async {
    final url = Endpoints.carModifications
          .replaceAll('{mark_id}', markId.toString())
          .replaceAll('{model_id}', modelId.toString())
          .replaceAll('{generation_id}', generationId.toString())
          .replaceAll('{configuration_id}', configurationId.toString());
    print(url);
    final response = await dio.get(
      url,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': perPage,
      },
    );
    print(response);

    final List<dynamic> data = response.data['data'];
    return data.map((json) => CarModificationModel.fromJson(json)).toList();
  }
}
