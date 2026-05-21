import '../../domain/entities/shop.dart';
import '../../../../core/utils/parsers.dart';
import 'shop_price_model.dart';

class ShopModel extends Shop {
  ShopModel({
    required super.id,
    required super.name,
    required super.address,
    required super.city,
    required super.onlinePurchaseAvailable,
    required super.whatsappPhone,
    required super.workingHours,
    required super.contacts,
    required super.phone,
    required super.email,
    required super.website,
    required super.prices,
    required super.lat,
    required super.lng,
    required super.distanceM,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    final pricesJson = json['prices'];
    final prices = (pricesJson is List)
        ? pricesJson
            .whereType<Map<String, dynamic>>()
            .map(ShopPriceModel.fromJson)
            .toList()
        : <ShopPriceModel>[];

    return ShopModel(
      id: toIntSafe(json['id']) ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      onlinePurchaseAvailable: json['online_purchase_available'] == true,
      whatsappPhone: json['whatsapp_phone']?.toString(),
      workingHours: json['working_hours']?.toString(),
      contacts: json['contacts'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      prices: prices,
      lat: toDoubleSafe(json['lat']),
      lng: toDoubleSafe(json['lng']),
      distanceM: toIntSafe(json['distance_m']),
    );
  }
}
