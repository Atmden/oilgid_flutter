import '../domain/entities/shop.dart';

class OilShopsMapArgs {
  final List<Shop> shops;
  final double? userLat;
  final double? userLng;

  OilShopsMapArgs({required this.shops, this.userLat, this.userLng});
}

class ShopPageArgs {
  final Shop shop;

  ShopPageArgs({required this.shop});
}

class ShopPageInput {
  final Shop? shop;
  final int? shopId;

  const ShopPageInput._({this.shop, this.shopId});

  factory ShopPageInput.fromShop(Shop shop) {
    return ShopPageInput._(shop: shop, shopId: shop.id);
  }

  factory ShopPageInput.fromId(int shopId) {
    return ShopPageInput._(shopId: shopId);
  }

  int? get resolvedShopId => shopId ?? shop?.id;
}