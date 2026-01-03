import '../models/car_mark_model.dart';
import '../../../../core/api/endpoints.dart';
import 'package:dio/dio.dart';

class CarMarkApi {
  final Dio dio;

  CarMarkApi(this.dio);

  Future<List<CarMarkModel>> getMarks({
    String? search,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await dio.get(
      Endpoints.carMarks,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': perPage,
      },
    );

    print(response);

    final List<dynamic> data = response.data['data'];
    return data.map((json) => CarMarkModel.fromJson(json)).toList();
  }
}
