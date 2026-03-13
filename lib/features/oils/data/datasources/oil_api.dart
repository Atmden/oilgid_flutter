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
  final Map<String, List<int>> selectedFacetIds;
  final Map<String, String> facetSearch;
  final String? sort;
  final String? search;

  const CatalogFilterState({
    this.selectedFacetIds = const {},
    this.facetSearch = const {},
    this.sort,
    this.search,
  });

  CatalogFilterState copyWith({
    Map<String, List<int>>? selectedFacetIds,
    Map<String, String>? facetSearch,
    String? sort,
    String? search,
    bool clearSort = false,
    bool clearSearch = false,
  }) {
    return CatalogFilterState(
      selectedFacetIds: selectedFacetIds ?? this.selectedFacetIds,
      facetSearch: facetSearch ?? this.facetSearch,
      sort: clearSort ? null : (sort ?? this.sort),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  int get selectedFiltersCount {
    return selectedFacetIds.values.fold<int>(0, (sum, ids) => sum + ids.length);
  }
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
        .map(
          (json) => CatalogFilterOption(
            id: json['id'] is int ? json['id'] as int : 0,
            title: json['title'] is String ? json['title'] as String : '',
          ),
        )
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

  const CatalogFacetsResult({required this.facets, required this.totalMatched});
}

class OilApi {
  final Dio dio;

  static const List<String> defaultFacetKeys = [
    'brand',
    'viscosity',
    'api',
    'acea',
    'oem',
    'ilsac',
    'iso',
    'isovg',
    'jaso',
    'din',
    'parker_hannifin',
    'part_number',
  ];

  OilApi(this.dio);

  Future<OilCatalogResult> getOilsCatalog({
    required int page,
    Map<String, List<int>>? selectedFacetIds,
    String? sort,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{'page': page};
    _appendSelectedFacetIds(queryParams, selectedFacetIds);
    if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;
    _appendSearch(queryParams, search);

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
      currentPage = meta['current_page'] is int
          ? meta['current_page'] as int
          : 1;
      lastPage = meta['last_page'] is int ? meta['last_page'] as int : 1;
    }
    final bool hasMore = currentPage < lastPage;

    return OilCatalogResult(items: items, hasMore: hasMore);
  }

  Future<CatalogFacetsResult> getCatalogFacets({
    Map<String, List<int>>? selectedFacetIds,
    Map<String, String>? facetSearch,
    Map<String, int>? facetLimit,
    int defaultFacetLimit = 50,
    String? sort,
    int? page,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    _appendSelectedFacetIds(queryParams, selectedFacetIds);
    _appendSearch(queryParams, search);
    _appendFacetSearch(queryParams, facetSearch);
    _appendFacetLimit(
      queryParams,
      facetLimit: facetLimit,
      facetSearch: facetSearch,
      defaultFacetLimit: defaultFacetLimit,
    );
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

  void _appendSelectedFacetIds(
    Map<String, dynamic> queryParams,
    Map<String, List<int>>? selectedFacetIds,
  ) {
    if (selectedFacetIds == null || selectedFacetIds.isEmpty) return;
    selectedFacetIds.forEach((facetKey, ids) {
      if (ids.isEmpty) return;
      queryParams['${facetKey}_ids[]'] = ids;
    });
  }

  void _appendFacetSearch(
    Map<String, dynamic> queryParams,
    Map<String, String>? facetSearch,
  ) {
    if (facetSearch == null || facetSearch.isEmpty) return;
    facetSearch.forEach((facetKey, searchText) {
      final normalized = searchText.trim();
      if (normalized.isEmpty) return;
      queryParams['facet_search[$facetKey]'] = normalized;
    });
  }

  void _appendFacetLimit(
    Map<String, dynamic> queryParams, {
    required Map<String, int>? facetLimit,
    required Map<String, String>? facetSearch,
    required int defaultFacetLimit,
  }) {
    final normalized = <String, int>{};
    if (facetLimit != null && facetLimit.isNotEmpty) {
      normalized.addAll(facetLimit);
    } else {
      for (final facetKey in defaultFacetKeys) {
        normalized[facetKey] = defaultFacetLimit;
      }
    }

    if (facetSearch != null) {
      for (final facetKey in facetSearch.keys) {
        normalized.putIfAbsent(facetKey, () => defaultFacetLimit);
      }
    }

    normalized.forEach((facetKey, limit) {
      if (limit <= 0) return;
      queryParams['facet_limit[$facetKey]'] = limit;
    });
  }

  void _appendSearch(Map<String, dynamic> queryParams, String? search) {
    final normalized = search?.trim();
    if (normalized == null || normalized.isEmpty) return;
    queryParams['search'] = normalized;
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
    final url = Endpoints.oilsByModification.replaceAll(
      '{modification_id}',
      modificationId.toString(),
    );
    final response = await dio.get(url);

    final List<dynamic> data = response.data['data'] ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map<OilType>((json) => OilTypeModel.fromJson(json))
        .toList();
  }
}
