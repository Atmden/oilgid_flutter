import '../entities/shop.dart';
import '../entities/shop_catalog_result.dart';
import '../entities/shop_details.dart';
import '../entities/shop_product_group.dart';
import '../../../oils/domain/entities/oil_item.dart';

abstract class ShopRepository {
  Future<List<Shop>> getShopsMarkers({
    required int oilId,
    double? lat,
    double? lng,
  });

  Future<List<OilItem>> getShopProducts({
    required int shopId,
    int? brandId,
    String? viscosityId,
    String? search,
  });

  Future<List<ShopProductGroup>> getShopProductGroups({
    required int shopId,
    required ShopProductGrouping by,
    String? search,
  });

  Future<ShopDetails> getShopDetails({required int shopId});

  Future<ShopCatalogResult> getShopsCatalog({
    required int page,
    int perPage,
    String? search,
    String? sort,
    double? lat,
    double? lng,
  });
}
