import '../../domain/entities/shop_price.dart';

class ShopPriceModel extends ShopPrice {
  const ShopPriceModel({
    required super.volumeId,
    required super.label,
    required super.value,
    required super.unit,
    super.price,
    super.quantity,
  });

  factory ShopPriceModel.fromJson(Map<String, dynamic> json) {
    return ShopPriceModel(
      volumeId: (json['volume_id'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      quantity: (json['quantity'] as num?)?.toInt(),
    );
  }
}
