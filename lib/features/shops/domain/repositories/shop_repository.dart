import '../entities/shop.dart';
import '../entities/shop_details.dart';
import '../../../oils/domain/entities/oil_item.dart';

abstract class ShopRepository {
  Future<List<Shop>> getShopsMarkers({
    required int oilId,
    double? lat,
    double? lng,
    int? radiusKm,
  });

  Future<List<OilItem>> getShopProducts({required int shopId});

  Future<ShopDetails> getShopDetails({required int shopId});
}
