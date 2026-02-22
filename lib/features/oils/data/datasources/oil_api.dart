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

/// Локальное состояние фильтров каталога (мультивыбор).
class CatalogFilterState {
  final List<int> brandIds;
  final List<int> viscosityIds;
  final List<int> apiIds;
  final List<int> aceaIds;
  final List<int> oemIds;
  final List<int> ilsacIds;
  final String? sort;

  const CatalogFilterState({
    this.brandIds = const [],
    this.viscosityIds = const [],
    this.apiIds = const [],
    this.aceaIds = const [],
    this.oemIds = const [],
    this.ilsacIds = const [],
    this.sort,
  });

  CatalogFilterState copyWith({
    List<int>? brandIds,
    List<int>? viscosityIds,
    List<int>? apiIds,
    List<int>? aceaIds,
    List<int>? oemIds,
    List<int>? ilsacIds,
    String? sort,
    bool clearSort = false,
  }) {
    return CatalogFilterState(
      brandIds: brandIds ?? this.brandIds,
      viscosityIds: viscosityIds ?? this.viscosityIds,
      apiIds: apiIds ?? this.apiIds,
      aceaIds: aceaIds ?? this.aceaIds,
      oemIds: oemIds ?? this.oemIds,
      ilsacIds: ilsacIds ?? this.ilsacIds,
      sort: clearSort ? null : (sort ?? this.sort),
    );
  }

  int get selectedFiltersCount =>
      brandIds.length +
      viscosityIds.length +
      apiIds.length +
      aceaIds.length +
      oemIds.length +
      ilsacIds.length;
}

/// Элемент списка фильтров.
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

/// Элемент фасетной группы.
class CatalogFacetOption extends CatalogFilterOption {
  final int count;
  final bool selected;

  CatalogFacetOption({
    required super.id,
    required super.title,
    required this.count,
    required this.selected,
  });

  static List<CatalogFacetOption> fromJsonList(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => CatalogFacetOption(
            id: json['id'] is int ? json['id'] as int : 0,
            title: json['title'] is String ? json['title'] as String : '',
            count: json['count'] is int ? json['count'] as int : 0,
            selected: json['selected'] == true,
          ),
        )
        .where((e) => e.id != 0)
        .toList();
  }
}

class CatalogFacetsResult {
  final Map<String, List<CatalogFacetOption>> facets;
  final int totalMatched;

  const CatalogFacetsResult({
    required this.facets,
    required this.totalMatched,
  });
}

class OilApi {
  final Dio dio;

  OilApi(this.dio);

  Future<OilCatalogResult> getOilsCatalog({
    required int page,
    List<int>? brandIds,
    List<int>? viscosityIds,
    List<int>? apiIds,
    List<int>? aceaIds,
    List<int>? oemIds,
    List<int>? ilsacIds,
    String? sort,
  }) async {
    final queryParams = <String, dynamic>{'page': page};
    if (brandIds != null && brandIds.isNotEmpty) {
      queryParams['brand_ids[]'] = brandIds;
    }
    if (viscosityIds != null && viscosityIds.isNotEmpty) {
      queryParams['viscosity_ids[]'] = viscosityIds;
    }
    if (apiIds != null && apiIds.isNotEmpty) {
      queryParams['api_ids[]'] = apiIds;
    }
    if (aceaIds != null && aceaIds.isNotEmpty) {
      queryParams['acea_ids[]'] = aceaIds;
    }
    if (oemIds != null && oemIds.isNotEmpty) {
      queryParams['oem_ids[]'] = oemIds;
    }
    if (ilsacIds != null && ilsacIds.isNotEmpty) {
      queryParams['ilsac_ids[]'] = ilsacIds;
    }
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

  Future<CatalogFacetsResult> getCatalogFacets({
    List<int>? brandIds,
    List<int>? viscosityIds,
    List<int>? apiIds,
    List<int>? aceaIds,
    List<int>? oemIds,
    List<int>? ilsacIds,
    String? sort,
    int? page,
  }) async {
    final queryParams = <String, dynamic>{};
    if (brandIds != null && brandIds.isNotEmpty) {
      queryParams['brand_ids[]'] = brandIds;
    }
    if (viscosityIds != null && viscosityIds.isNotEmpty) {
      queryParams['viscosity_ids[]'] = viscosityIds;
    }
    if (apiIds != null && apiIds.isNotEmpty) queryParams['api_ids[]'] = apiIds;
    if (aceaIds != null && aceaIds.isNotEmpty) {
      queryParams['acea_ids[]'] = aceaIds;
    }
    if (oemIds != null && oemIds.isNotEmpty) queryParams['oem_ids[]'] = oemIds;
    if (ilsacIds != null && ilsacIds.isNotEmpty) {
      queryParams['ilsac_ids[]'] = ilsacIds;
    }
    if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;
    if (page != null && page > 0) queryParams['page'] = page;

    final response = await dio.get(
      Endpoints.oilsCatalogFacets,
      queryParameters: queryParams,
    );

    final data = response.data;
    final root = data is Map ? data['data'] : null;
    final facetsRaw = root is Map ? root['facets'] : null;
    final totalMatchedRaw = root is Map ? root['totalMatched'] : null;

    final facets = <String, List<CatalogFacetOption>>{};
    if (facetsRaw is Map) {
      facetsRaw.forEach((key, value) {
        if (key is String) {
          facets[key] = CatalogFacetOption.fromJsonList(value);
        }
      });
    }

    final totalMatched = totalMatchedRaw is int ? totalMatchedRaw : 0;
    return CatalogFacetsResult(facets: facets, totalMatched: totalMatched);
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
