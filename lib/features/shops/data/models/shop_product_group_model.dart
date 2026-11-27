import '../../domain/entities/shop_product_group.dart';

class ShopProductGroupModel extends ShopProductGroup {
  const ShopProductGroupModel({
    required super.type,
    required super.id,
    required super.title,
    required super.logo,
    required super.productsCount,
  });

  factory ShopProductGroupModel.fromJson(Map<String, dynamic> json) {
    return ShopProductGroupModel(
      type: json['type'] == ShopProductGrouping.viscosity.apiValue
          ? ShopProductGrouping.viscosity
          : ShopProductGrouping.brand,
      id: (json['id'] as num?)?.toInt(),
      title: json['title']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      productsCount: (json['products_count'] as num?)?.toInt() ?? 0,
    );
  }
}
