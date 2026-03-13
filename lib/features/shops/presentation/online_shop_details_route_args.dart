import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/shops/domain/entities/shop.dart';

class OnlineShopDetailsArgs {
  final Shop shop;
  final OilItem oilItem;
  final String volume;
  final String description;

  OnlineShopDetailsArgs({
    required this.shop,
    required this.oilItem,
    this.volume = '',
    this.description = '',
  });
}
