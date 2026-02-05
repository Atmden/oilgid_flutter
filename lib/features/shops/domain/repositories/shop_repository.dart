import '../entities/shop.dart';

abstract class ShopRepository {
  Future<List<Shop>> getShopsMarkers({
    required int oilId,
    double? lat,
    double? lng,
    int? radiusKm,
  });
}
