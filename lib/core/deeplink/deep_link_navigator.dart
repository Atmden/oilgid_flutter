import 'package:flutter/widgets.dart';
import 'package:oil_gid/core/deeplink/deep_link_parser.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:oil_gid/features/shops/presentation/shop_route_args.dart';

/// Открывает экран для [uri]. Возвращает false, если ссылка не ведёт внутрь
/// приложения (её можно открыть во внешнем браузере).
bool openDeepLink(NavigatorState navigator, Uri uri) {
  final action = DeepLinkParser.parse(uri);
  switch (action) {
    case OpenShopDeepLink(:final shopId):
      navigator.pushNamed('/shop', arguments: ShopPageInput.fromId(shopId));
    case OpenOilDeepLink(:final oilId):
      navigator.pushNamed(
        '/oil_details',
        arguments: OilDetailsInput.fromId(oilId),
      );
    case OpenNotificationsDeepLink():
      navigator.pushNamed('/notifications');
    case IgnoreDeepLink():
      return false;
  }
  return true;
}
