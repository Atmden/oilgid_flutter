class ShopGalleryImage {
  final String thumb;
  final String photo;

  const ShopGalleryImage({
    required this.thumb,
    required this.photo,
  });
}

class ShopDetails {
  final int id;
  final String name;
  final String address;
  final String? contacts;
  final String? phone;
  final String? email;
  final String? website;
  final double? lat;
  final double? lng;
  final List<ShopGalleryImage> gallery;

  const ShopDetails({
    required this.id,
    required this.name,
    required this.address,
    this.contacts,
    this.phone,
    this.email,
    this.website,
    this.lat,
    this.lng,
    required this.gallery,
  });
}
