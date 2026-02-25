import 'package:flutter/material.dart';
import 'package:oil_gid/core/utils/navigation_launcher.dart';
import 'package:oil_gid/features/shops/domain/entities/shop.dart';
import 'package:oil_gid/features/shops/presentation/shop_products_route_args.dart';
import 'package:oil_gid/features/shops/presentation/shop_route_args.dart';
import 'package:oil_gid/themes/app_colors.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  Shop? _shop;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ShopPageArgs) {
      _shop = args.shop;
    }
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(shop.name),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoCard(shop: shop),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: NavigationLauncher.canBuildRoute(
                    lat: shop.lat,
                    lng: shop.lng,
                    address: shop.address,
                  )
                  ? () => NavigationLauncher.openRoute(
                        context: context,
                        shopName: shop.name,
                        lat: shop.lat,
                        lng: shop.lng,
                        address: shop.address,
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
                    shopName: shop.name,
                  ),
                );
              },
              child: const Text('Посмотреть все товары магазина'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Shop shop;

  const _InfoCard({required this.shop});

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
            shop.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Адрес', value: shop.address),
          _InfoRow(label: 'Телефон', value: shop.phone),
          _InfoRow(label: 'Email', value: shop.email),
          _InfoRow(label: 'Сайт', value: shop.website),
          if (shop.price != null)
            _InfoRow(label: 'Цена', value: shop.price!.toStringAsFixed(2)),
          if (shop.quantity != null)
            _InfoRow(label: 'Наличие', value: shop.quantity.toString()),
          if (shop.distanceM != null)
            _InfoRow(label: 'Расстояние', value: '${shop.distanceM} м'),
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
