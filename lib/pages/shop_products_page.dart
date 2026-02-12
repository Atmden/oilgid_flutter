import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:oil_gid/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:oil_gid/features/shops/presentation/shop_products_route_args.dart';
import 'package:oil_gid/themes/app_colors.dart';

class ShopProductsPage extends StatefulWidget {
  const ShopProductsPage({super.key});

  @override
  State<ShopProductsPage> createState() => _ShopProductsPageState();
}

class _ShopProductsPageState extends State<ShopProductsPage> {
  final _shopRepository = ShopRepositoryImpl(AppApi().shopModelApi);

  bool _initialized = false;
  int? _shopId;
  String _shopName = 'Товары магазина';
  Future<List<OilItem>>? _productsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ShopProductsArgs) {
      _shopId = args.shopId;
      _shopName = args.shopName;
      _productsFuture = _shopRepository.getShopProducts(shopId: args.shopId);
    }
  }

  void _retryLoad() {
    final shopId = _shopId;
    if (shopId == null) return;
    setState(() {
      _productsFuture = _shopRepository.getShopProducts(shopId: shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(_shopName),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final productsFuture = _productsFuture;
    if (productsFuture == null) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    return FutureBuilder<List<OilItem>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Не удалось загрузить товары магазина'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _retryLoad,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('В этом магазине пока нет товаров'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ProductTile(item: item);
          },
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  final OilItem item;

  const _ProductTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (item.brandTitle.isNotEmpty) subtitleParts.add(item.brandTitle);
    if (item.viscosityTitle.isNotEmpty) subtitleParts.add(item.viscosityTitle);
    final subtitle = subtitleParts.join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/oil_details',
            arguments: OilDetailsArgs(item: item, volume: '', description: ''),
          );
        },
        leading: item.thumb.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl: item.thumb,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const SizedBox(width: 24, height: 24),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.oil_barrel),
                  ),
                ),
              )
            : const Icon(Icons.oil_barrel),
        title: Text(
          item.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }
}
