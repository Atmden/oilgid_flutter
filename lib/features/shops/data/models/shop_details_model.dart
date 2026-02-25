import 'package:oil_gid/core/utils/parsers.dart';
import 'package:oil_gid/features/shops/domain/entities/shop_details.dart';

class ShopGalleryImageModel extends ShopGalleryImage {
  const ShopGalleryImageModel({
    required super.thumb,
    required super.photo,
  });

  factory ShopGalleryImageModel.fromJson(Map<String, dynamic> json) {
    return ShopGalleryImageModel(
      thumb: (json['thumb'] ?? '').toString(),
      photo: (json['photo'] ?? '').toString(),
    );
  }
}

class ShopDetailsModel extends ShopDetails {
  const ShopDetailsModel({
    required super.id,
    required super.name,
    required super.address,
    super.contacts,
    super.phone,
    super.email,
    super.website,
    super.lat,
    super.lng,
    required super.gallery,
  });

  factory ShopDetailsModel.fromJson(Map<String, dynamic> json) {
    final galleryRaw = json['gallery'] as List<dynamic>? ?? const [];
    final gallery = galleryRaw
        .whereType<Map<String, dynamic>>()
        .map(ShopGalleryImageModel.fromJson)
        .toList();

    return ShopDetailsModel(
      id: toIntSafe(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      contacts: json['contacts']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      lat: toDoubleSafe(json['lat']),
      lng: toDoubleSafe(json['lng']),
      gallery: gallery,
    );
  }
}
