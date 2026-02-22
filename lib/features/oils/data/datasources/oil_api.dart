import 'package:dio/dio.dart';
import '../../../../core/api/endpoints.dart';
import '../../domain/entities/oil_item.dart';
import '../../domain/entities/oil_type.dart';
import '../models/oil_item_model.dart';
import '../models/oil_type_model.dart';

/// Результат запроса каталога масел: список элементов и признак наличия следующей страницы.
class OilCatalogResult {
  final List<OilItem> items;
  final bool hasMore;

  OilCatalogResult({required this.items, required this.hasMore});
}

/// Элемент списка фильтров каталога (бренд, вязкость, спецификация).
class CatalogFilterOption {
  final int id;
  final String title;

  CatalogFilterOption({required this.id, required this.title});

  static List<CatalogFilterOption> fromJsonList(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => CatalogFilterOption(
              id: json['id'] is int ? json['id'] as int : 0,
              title: json['title'] is String ? json['title'] as String : '',
            ))
        .where((e) => e.id != 0)
        .toList();
  }
}

class OilApi {
  final Dio dio;

  OilApi(this.dio);

  Future<OilCatalogResult> getOilsCatalog({
    required int page,
    int? brandId,
    int? viscosityId,
    String? sort,
  }) async {
    final queryParams = <String, dynamic>{'page': page};
    if (brandId != null) queryParams['brand_ids'] = brandId;
    if (viscosityId != null) queryParams['viscosity_ids'] = viscosityId;
    if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;

    final response = await dio.get(
      Endpoints.oilsCatalog,
      queryParameters: queryParams,
    );

    final data = response.data;
    final inner = data is Map ? data['data'] : null;
    final list = inner is Map ? inner['data'] : null;
    final meta = inner is Map ? inner['meta'] : null;

    final List<OilItem> items = (list is List)
        ? list
            .whereType<Map<String, dynamic>>()
            .map<OilItem>((json) => OilItemModel.fromJson(json))
            .toList()
        : [];

    int currentPage = 1;
    int lastPage = 1;
    if (meta is Map) {
      currentPage = meta['current_page'] is int ? meta['current_page'] as int : 1;
      lastPage = meta['last_page'] is int ? meta['last_page'] as int : 1;
    }
    final bool hasMore = currentPage < lastPage;

    return OilCatalogResult(items: items, hasMore: hasMore);
  }

  Future<List<CatalogFilterOption>> getCatalogFilterBrands() async {
    final response = await dio.get(Endpoints.oilsCatalogFiltersBrands);
    final data = response.data is Map ? response.data['data'] : null;
    return CatalogFilterOption.fromJsonList(data ?? []);
  }

  Future<List<CatalogFilterOption>> getCatalogFilterViscosities() async {
    final response = await dio.get(Endpoints.oilsCatalogFiltersViscosities);
    final data = response.data is Map ? response.data['data'] : null;
    return CatalogFilterOption.fromJsonList(data ?? []);
  }

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
