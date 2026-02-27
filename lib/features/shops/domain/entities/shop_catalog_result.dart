import 'shop.dart';

class ShopCatalogResult {
  final List<Shop> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;
  final String? firstLink;
  final String? lastLink;
  final String? prevLink;
  final String? nextLink;

  const ShopCatalogResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
    required this.firstLink,
    required this.lastLink,
    required this.prevLink,
    required this.nextLink,
  });

  bool get hasMore => currentPage < lastPage;
}
