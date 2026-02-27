import 'package:oil_gid/core/utils/parsers.dart';
import 'package:oil_gid/features/shops/domain/entities/shop_catalog_result.dart';

import 'shop_model.dart';

class ShopCatalogResultModel extends ShopCatalogResult {
  const ShopCatalogResultModel({
    required super.items,
    required super.currentPage,
    required super.lastPage,
    required super.perPage,
    required super.total,
    required super.from,
    required super.to,
    required super.firstLink,
    required super.lastLink,
    required super.prevLink,
    required super.nextLink,
  });

  factory ShopCatalogResultModel.fromJson(Map<String, dynamic> json) {
    final inner = json['data'] as Map<String, dynamic>? ?? const {};
    final list = inner['data'] as List<dynamic>? ?? const [];
    final meta = inner['meta'] as Map<String, dynamic>? ?? const {};
    final links = inner['links'] as Map<String, dynamic>? ?? const {};

    final items = list
        .whereType<Map<String, dynamic>>()
        .map(ShopModel.fromJson)
        .toList();

    return ShopCatalogResultModel(
      items: items,
      currentPage: toIntSafe(meta['current_page']) ?? 1,
      lastPage: toIntSafe(meta['last_page']) ?? 1,
      perPage: toIntSafe(meta['per_page']) ?? 20,
      total: toIntSafe(meta['total']) ?? items.length,
      from: toIntSafe(meta['from']),
      to: toIntSafe(meta['to']),
      firstLink: links['first']?.toString(),
      lastLink: links['last']?.toString(),
      prevLink: links['prev']?.toString(),
      nextLink: links['next']?.toString(),
    );
  }
}
