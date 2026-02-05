import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';
import '../datasource/shop_model_api.dart';

class ShopRepositoryImpl implements ShopRepository {
  final ShopModelApi api;

  ShopRepositoryImpl(this.api);

  @override
  Future<List<Shop>> getShopsMarkers({
    required int oilId,
    double? lat,
    double? lng,
    int? radiusKm,
  }) {
    return api.getShopsMarkers(oilId: oilId, lat: lat, lng: lng, radiusKm: radiusKm);
  }
}