import '../../../../core/api/endpoints.dart';
import 'package:dio/dio.dart';
import '../models/shop_model.dart';

class ShopModelApi {
  final Dio dio;

  ShopModelApi(this.dio);

  Future<List<ShopModel>> getShopsMarkers({
    required int oilId,
    double? lat,
    double? lng,
    int? radiusKm,
  }) async {

    final query = <String, dynamic>{};
    if (lat != null) query['lat'] = lat;
    if (lng != null) query['lng'] = lng;
    if (radiusKm != null) query['radius_km'] = radiusKm;

    final response = await dio.get(
      Endpoints.oilShopsMarkers.replaceAll('{oil_id}', oilId.toString()),
      queryParameters: query.isEmpty ? null : query,
    );
    print(response.data);
    final List<dynamic> data = response.data['data'];
    return data.map((json) => ShopModel.fromJson(json)).toList();
  }
}