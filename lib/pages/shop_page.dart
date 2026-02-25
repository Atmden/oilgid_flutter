import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/core/utils/navigation_launcher.dart';
import 'package:oil_gid/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:oil_gid/features/shops/domain/entities/shop.dart';
import 'package:oil_gid/features/shops/domain/entities/shop_details.dart';
import 'package:oil_gid/features/shops/presentation/widgets/shop_gallery.dart';
import 'package:oil_gid/features/shops/presentation/shop_products_route_args.dart';
import 'package:oil_gid/features/shops/presentation/shop_route_args.dart';
import 'package:oil_gid/themes/app_colors.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final _shopRepository = ShopRepositoryImpl(AppApi().shopModelApi);
  Shop? _shop;
  bool _initialized = false;
  Future<ShopDetails>? _detailsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ShopPageArgs) {
      _shop = args.shop;
      _detailsFuture = _shopRepository.getShopDetails(shopId: args.shop.id);
    }
  }

  void _retryLoadDetails() {
    final shop = _shop;
    if (shop == null) return;
    setState(() {
      _detailsFuture = _shopRepository.getShopDetails(shopId: shop.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shop = _shop;
    if (shop == null) {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(shop.name),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<ShopDetails>(
            future: detailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError && !snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Не удалось загрузить информацию о магазине'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _retryLoadDetails,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                );
              }

              final details = snapshot.data;
              final name = _resolvedText(details?.name, shop.name);
              final address = _resolvedText(details?.address, shop.address);
              final phone = _resolvedOptional(details?.phone, shop.phone);
              final email = _resolvedOptional(details?.email, shop.email);
              final website = _resolvedOptional(details?.website, shop.website);
              final lat = details?.lat ?? shop.lat;
              final lng = details?.lng ?? shop.lng;
              final gallery = details?.gallery ?? const <ShopGalleryImage>[];

              return ListView(
                children: [
                  _InfoCard(
                    shopName: name,
                    address: address,
                    phone: phone,
                    email: email,
                    website: website,
                    price: shop.price,
                    quantity: shop.quantity,
                    distanceM: shop.distanceM,
                  ),
                  const SizedBox(height: 12),
                  if (gallery.isNotEmpty) ...[
                    const Text(
                      'Фотографии магазина',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShopGallery(gallery: gallery),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: NavigationLauncher.canBuildRoute(
                          lat: lat,
                          lng: lng,
                          address: address,
                        )
                        ? () => NavigationLauncher.openRoute(
                              context: context,
                              shopName: name,
                              lat: lat,
                              lng: lng,
                              address: address,
                            )
                        : null,
                    child: const Text('Проложить маршрут'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/shop_products',
                        arguments: ShopProductsArgs(
                          shopId: shop.id,
                          shopName: name,
                        ),
                      );
                    },
                    child: const Text('Посмотреть все товары магазина'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
}

class _InfoCard extends StatelessWidget {
  final String shopName;
  final String address;
  final String? phone;
  final String? email;
  final String? website;
  final double? price;
  final int? quantity;
  final int? distanceM;

  const _InfoCard({
    required this.shopName,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.price,
    required this.quantity,
    required this.distanceM,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shopName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Адрес', value: address),
          _InfoRow(label: 'Телефон', value: phone),
          _InfoRow(label: 'Email', value: email),
          _InfoRow(label: 'Сайт', value: website),
          if (price != null) _InfoRow(label: 'Цена', value: price!.toStringAsFixed(2)),
          if (quantity != null) _InfoRow(label: 'Наличие', value: quantity.toString()),
          if (distanceM != null) _InfoRow(label: 'Расстояние', value: '$distanceM м'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
