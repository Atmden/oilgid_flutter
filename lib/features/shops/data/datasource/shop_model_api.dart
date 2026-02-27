import '../../../../core/api/endpoints.dart';
import 'package:dio/dio.dart';
import '../../../oils/domain/entities/oil_item.dart';
import '../../../oils/data/models/oil_item_model.dart';
import '../models/shop_model.dart';
import '../models/shop_catalog_result_model.dart';
import '../models/shop_details_model.dart';

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
    final List<dynamic> data = response.data['data'];
    return data.map((json) => ShopModel.fromJson(json)).toList();
  }

  Future<List<OilItem>> getShopProducts({required int shopId}) async {
    final response = await dio.get(
      Endpoints.shopProducts.replaceAll('{shop_id}', shopId.toString()),
    );

    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map<OilItem>(OilItemModel.fromJson)
        .toList();
  }

  Future<ShopDetailsModel> getShopDetails({required int shopId}) async {
    final response = await dio.get(
      Endpoints.shopDetails.replaceAll('{shop_id}', shopId.toString()),
    );

    final data = response.data['data'] as Map<String, dynamic>? ?? const {};
    return ShopDetailsModel.fromJson(data);
  }

  Future<ShopCatalogResultModel> getShopsCatalog({
    required int page,
    int perPage = 20,
    String? search,
    String? sort,
    double? lat,
    double? lng,
  }) async {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};
    final normalizedSearch = search?.trim();
    if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }
    if (sort != null && sort.isNotEmpty) {
      query['sort'] = sort;
    }
    if (lat != null) query['lat'] = lat;
    if (lng != null) query['lng'] = lng;

    final response = await dio.get(
      Endpoints.shopCatalog,
      queryParameters: query,
    );
    return ShopCatalogResultModel.fromJson(
      response.data as Map<String, dynamic>? ?? const {},
    );
  }
}
