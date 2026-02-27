import '../../domain/entities/shop.dart';
import '../../domain/entities/shop_catalog_result.dart';
import '../../domain/entities/shop_details.dart';
import '../../../oils/domain/entities/oil_item.dart';
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
    return api.getShopsMarkers(
      oilId: oilId,
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
  }

  @override
  Future<List<OilItem>> getShopProducts({required int shopId}) {
    return api.getShopProducts(shopId: shopId);
  }

  @override
  Future<ShopDetails> getShopDetails({required int shopId}) {
    return api.getShopDetails(shopId: shopId);
  }

  @override
  Future<ShopCatalogResult> getShopsCatalog({
    required int page,
    int perPage = 20,
    String? search,
    String? sort,
    double? lat,
    double? lng,
  }) {
    return api.getShopsCatalog(
      page: page,
      perPage: perPage,
      search: search,
      sort: sort,
      lat: lat,
      lng: lng,
    );
  }
}
