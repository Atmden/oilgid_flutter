import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/core/utils/navigation_launcher.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/oils/presentation/widgets/oil_approvals_group.dart';
import 'package:oil_gid/features/oils/presentation/widgets/oil_gallery.dart';
import 'package:oil_gid/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:oil_gid/features/shops/domain/entities/shop.dart';
import 'package:oil_gid/features/shops/domain/entities/shop_details.dart';
import 'package:oil_gid/features/shops/presentation/online_shop_details_route_args.dart';
import 'package:oil_gid/features/shops/presentation/shop_products_route_args.dart';
import 'package:oil_gid/features/shops/presentation/widgets/shop_gallery.dart';
import 'package:oil_gid/themes/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class OnlineShopDetailsPage extends StatefulWidget {
  const OnlineShopDetailsPage({super.key});

  @override
  State<OnlineShopDetailsPage> createState() => _OnlineShopDetailsPageState();
}

class _OnlineShopDetailsPageState extends State<OnlineShopDetailsPage> {
  final _shopRepository = ShopRepositoryImpl(AppApi().shopModelApi);
  bool _initialized = false;
  Shop? _shop;
  OilItem? _oilItem;
  String _volume = '';
  String _description = '';
  Future<ShopDetails>? _detailsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OnlineShopDetailsArgs) {
      _shop = args.shop;
      _oilItem = args.oilItem;
      _volume = args.volume;
      _description = args.description;
      _detailsFuture = _shopRepository.getShopDetails(shopId: args.shop.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = _shop;
    final oil = _oilItem;
    if (shop == null || oil == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Магазин'),
        ),
        body: const Center(child: Text('Нет данных о магазине')),
      );
    }

    final detailsFuture = _detailsFuture;
    if (detailsFuture == null) {
      return const SizedBox.shrink();
    }

    final productImages = oil.resolveImages();
    final canShowBuyButton =
        shop.onlinePurchaseAvailable &&
        (shop.whatsappPhone?.trim().isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(shop.name),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<ShopDetails>(
          future: detailsFuture,
          builder: (context, snapshot) {
            final details = snapshot.data;
            final shopName = _resolvedText(details?.name, shop.name);
            final address = _resolvedText(details?.address, shop.address);
            final workingHours = _resolvedOptional(
              details?.workingHours,
              shop.workingHours,
            );
            final phone = _resolvedOptional(details?.phone, shop.phone);
            final email = _resolvedOptional(details?.email, shop.email);
            final website = _resolvedOptional(details?.website, shop.website);
            final routeLat = details?.lat ?? shop.lat;
            final routeLng = details?.lng ?? shop.lng;
            final canBuildRoute = NavigationLauncher.canBuildRoute(
              lat: routeLat,
              lng: routeLng,
            );
            final gallery = details?.gallery ?? const <ShopGalleryImage>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (snapshot.hasError && !snapshot.hasData)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Не удалось загрузить данные магазина'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _detailsFuture = _shopRepository.getShopDetails(
                                shopId: shop.id,
                              );
                            });
                          },
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                if (gallery.isNotEmpty) ...[
                  const Text(
                    'Фотографии магазина',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ShopGallery(gallery: gallery),
                  const SizedBox(height: 12),
                ],
                InfoBlock(
                  title: shopName,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Адрес', address, 'address'),
                      _infoRow('Режим работы', workingHours, 'working_hours'),
                      _infoRow('Телефон', phone, 'phone'),
                      _infoRow('Email', email, 'email'),
                      _infoRow('Сайт', website, 'website'),
                      if (shop.price != null)
                        _infoRow(
                          'Цена',
                          shop.price!.toStringAsFixed(2),
                          'price',
                        ),
                      if (shop.quantity != null)
                        _infoRow(
                          'Наличие',
                          shop.quantity.toString(),
                          'quantity',
                        ),
                      if (shop.distanceM != null)
                        _infoRow(
                          'Расстояние',
                          '${shop.distanceM} м',
                          'distance',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                InfoBlock(
                  title: 'Товар который вы смотрели',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        oil.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                      if (_volume.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        InfoRow(label: 'Требуемый объем', value: '$_volume л.'),
                      ],
                      if (_description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        InfoRow(label: 'Описание', value: _description),
                      ],
                      const SizedBox(height: 8),
                      OilGallery(images: productImages),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                InfoBlock(
                  title: 'Характеристики',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoRow(label: 'Бренд', value: oil.brandTitle),
                      InfoRow(label: 'Вязкость/Тип масла', value: oil.viscosityTitle),
                      const SizedBox(height: 8),
                      if (oil.specification != null)
                        ApprovalsGroup(
                          title: 'ACEA',
                          values: oil.specification!.aceas,
                        ),
                      if (oil.specification != null)
                        ApprovalsGroup(
                          title: 'API',
                          values: oil.specification!.apis,
                        ),
                      if (oil.specification != null)
                        ApprovalsGroup(
                          title: 'Допуски и спецификации',
                          values: oil.specification!.oemApprovals,
                        ),
                      if (oil.specification != null)
                        ApprovalsGroup(
                          title: 'ILSAC',
                          values: oil.specification!.ilsacs,
                        ),
                      if (oil.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Описание',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          oil.description,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (canBuildRoute) ...[
                  ElevatedButton(
                    onPressed: () => NavigationLauncher.openRoute(
                      context: context,
                      shopName: shopName,
                      lat: routeLat,
                      lng: routeLng,
                    ),
                    child: const Text('Проложить маршрут'),
                  ),
                  const SizedBox(height: 8),
                ],
                if (canShowBuyButton) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLight,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => NavigationLauncher.openWhatsAppPurchase(
                      context: context,
                      phone: shop.whatsappPhone!,
                      message: _buildPurchaseMessage(
                        shopName: shopName,
                        oil: oil,
                        volume: _volume,
                        customDescription: _description,
                      ),
                    ),
                    child: const Text(
                      'Купить онлайн',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/shop_products',
                      arguments: ShopProductsArgs(
                        shopId: shop.id,
                        shopName: shop.name,
                      ),
                    );
                  },
                  child: const Text('Перейти к товарам магазина'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _buildPurchaseMessage({
    required String shopName,
    required OilItem oil,
    required String volume,
    required String customDescription,
  }) {
    final lines = <String>[
      'Здравствуйте! Хочу купить масло.',
      'Магазин: $shopName',
      'Наименование: ${oil.title}',
      'Бренд: ${oil.brandTitle}',
      'Вязкость/Тип масла: ${oil.viscosityTitle}',
    ];
    if (volume.trim().isNotEmpty) {
      lines.add('Требуемый объем: $volume л.');
    }
    if (customDescription.trim().isNotEmpty) {
      lines.add('Комментарий: $customDescription');
    }
    return lines.join('\n');
  }

  String _resolvedText(String? primary, String fallback) {
    final normalizedPrimary = primary?.trim() ?? '';
    if (normalizedPrimary.isNotEmpty) return normalizedPrimary;
    return fallback;
  }

  String? _resolvedOptional(String? primary, String? fallback) {
    final normalizedPrimary = primary?.trim() ?? '';
    if (normalizedPrimary.isNotEmpty) return normalizedPrimary;
    final normalizedFallback = fallback?.trim() ?? '';
    return normalizedFallback.isEmpty ? null : normalizedFallback;
  }

  Widget _infoRow(String label, String? value, String? type) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    void open(String uri) => launchUrl(Uri.parse(uri));

    Widget row(Widget child) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    switch (type) {
      case 'phone':
        final phone = value.replaceAll(' ', '');
        return row(
          GestureDetector(
            onTap: () => open('tel:$phone'),
            child: Text(
              phone,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
      case 'email':
        return row(
          GestureDetector(
            onTap: () => open('mailto:$value'),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
      case 'website':
        return row(
          GestureDetector(
            onTap: () => open(value),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
      default:
        return row(Text(value));
    }
  }
}
