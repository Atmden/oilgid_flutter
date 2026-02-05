import '../../domain/entities/shop.dart';
import '../../../../core/utils/parsers.dart';

class ShopModel extends Shop {
  ShopModel({
    required super.id,
    required super.name,
    required super.address,
    required super.contacts,
    required super.phone,
    required super.email,
    required super.website,
    required super.price,
    required super.quantity,
    required super.lat,
    required super.lng,
    required super.distanceM,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: toIntSafe(json['id']) ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      contacts: json['contacts'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      price: toDoubleSafe(json['price']),
      quantity: toIntSafe(json['quantity']),
      lat: toDoubleSafe(json['lat']),
      lng: toDoubleSafe(json['lng']),
      distanceM: toIntSafe(json['distance_m']),
    );
  }
}
