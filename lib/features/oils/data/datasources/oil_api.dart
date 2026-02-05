import 'package:dio/dio.dart';
import '../../../../core/api/endpoints.dart';
import '../../domain/entities/oil_type.dart';
import '../models/oil_type_model.dart';

class OilApi {
  final Dio dio;

  OilApi(this.dio);

  Future<List<OilType>> getOilsByModification({
    required int modificationId,
  }) async {
    final url = Endpoints.oilsByModification
        .replaceAll('{modification_id}', modificationId.toString());
    final response = await dio.get(url);

    final List<dynamic> data = response.data['data'] ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map<OilType>((json) => OilTypeModel.fromJson(json))
        .toList();
  }
}
