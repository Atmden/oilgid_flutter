import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:oil_gid/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:oil_gid/features/shops/domain/entities/shop_price.dart';
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
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ProductTile(
              item: item,
              shopId: _shopId,
              shopRepository: _shopRepository,
            );
          },
        );
      },
    );
  }
}

String _formatPrice(double price) {
  final s = price.truncate().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

class _ProductTile extends StatefulWidget {
  final OilItem item;
  final int? shopId;
  final ShopRepositoryImpl shopRepository;

  const _ProductTile({
    required this.item,
    required this.shopRepository,
    this.shopId,
  });

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  static const double _leadingLeftInset = 16;

  bool _expanded = false;
  Future<List<ShopPrice>>? _pricesFuture;

  void _toggleExpanded() {
    final shopId = widget.shopId;
    if (shopId == null) return;
    setState(() {
      _expanded = !_expanded;
      _pricesFuture ??= widget.shopRepository
          .getShopsMarkers(oilId: widget.item.id)
          .then((shops) {
            for (final shop in shops) {
              if (shop.id == shopId) return shop.prices;
            }
            return const <ShopPrice>[];
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final subtitleParts = <String>[];
    if (item.brandTitle.isNotEmpty) subtitleParts.add(item.brandTitle);
    if (item.viscosityTitle.isNotEmpty) subtitleParts.add(item.viscosityTitle);
    final subtitle = subtitleParts.join(' • ');
    final previewUrl = item.images.isNotEmpty ? item.images.first : item.thumb;
    final minPrice = item.minPrice;
    final canExpand = widget.shopId != null && minPrice != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.only(
              left: _leadingLeftInset,
              right: 4,
              top: 4,
              bottom: 4,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/oil_details',
                arguments: OilDetailsInput.fromItem(
                  item,
                  shopId: widget.shopId,
                ),
              );
            },
            leading: previewUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: CachedNetworkImage(
                          imageUrl: previewUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const SizedBox(width: 24, height: 24),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.oil_barrel),
                        ),
                      ),
                    ),
                  )
                : const Icon(Icons.oil_barrel),
            title: Text(
              item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                if (minPrice != null && !_expanded)
                  Text(
                    'от ${_formatPrice(minPrice)} ₸',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            trailing: canExpand
                ? IconButton(
                    onPressed: _toggleExpanded,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(_leadingLeftInset, 0, 16, 12),
              child: FutureBuilder<List<ShopPrice>>(
                future: _pricesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text('Не удалось загрузить цены');
                  }
                  final prices = snapshot.data ?? const <ShopPrice>[];
                  if (prices.isEmpty) {
                    return const Text('Цены по объёмам не указаны');
                  }
                  return Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: prices
                        .map(
                          (p) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.label,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.price != null
                                      ? '${_formatPrice(p.price!)} ₸'
                                      : '—',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
