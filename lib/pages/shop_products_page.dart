import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:oil_gid/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:oil_gid/features/shops/domain/entities/shop_price.dart';
import 'package:oil_gid/features/shops/domain/entities/shop_product_group.dart';
import 'package:oil_gid/features/shops/presentation/shop_products_route_args.dart';
import 'package:oil_gid/themes/app_colors.dart';

/// Режим отображения товаров магазина: аккордеон по брендам / по вязкости или плоский список.
enum _ViewMode {
  brands('По брендам', ShopProductGrouping.brand),
  viscosity('По вязкости', ShopProductGrouping.viscosity),
  list('Одним списком', null);

  final String label;
  final ShopProductGrouping? grouping;

  const _ViewMode(this.label, this.grouping);
}

class ShopProductsPage extends StatefulWidget {
  const ShopProductsPage({super.key});

  @override
  State<ShopProductsPage> createState() => _ShopProductsPageState();
}

class _ShopProductsPageState extends State<ShopProductsPage> {
  final _shopRepository = ShopRepositoryImpl(AppApi().shopModelApi);
  final _searchController = TextEditingController();

  bool _initialized = false;
  int? _shopId;
  String _shopName = 'Товары магазина';
  _ViewMode _mode = _ViewMode.brands;
  String _search = '';
  Timer? _searchDebounce;

  Future<List<ShopProductGroup>>? _groupsFuture;
  Future<List<OilItem>>? _productsFuture;

  // Товары раскрытых групп: грузятся лениво и живут до смены режима или поиска
  final Map<String, Future<List<OilItem>>> _groupProducts = {};
  final Set<String> _expandedGroups = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ShopProductsArgs) {
      _shopId = args.shopId;
      _shopName = args.shopName;
      _load();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    final shopId = _shopId;
    if (shopId == null) return;

    _groupProducts.clear();
    _expandedGroups.clear();
    final grouping = _mode.grouping;
    if (grouping == null) {
      _groupsFuture = null;
      _productsFuture = _shopRepository.getShopProducts(
        shopId: shopId,
        search: _search,
      );
    } else {
      _productsFuture = null;
      _groupsFuture = _shopRepository.getShopProductGroups(
        shopId: shopId,
        by: grouping,
        search: _search,
      );
    }
  }

  void _reload() => setState(_load);

  void _selectMode(_ViewMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _load();
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final search = value.trim();
      if (!mounted || search == _search) return;
      setState(() {
        _search = search;
        _load();
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  String _groupKey(ShopProductGroup group) => '${group.type.name}:${group.id}';

  void _toggleGroup(ShopProductGroup group) {
    final shopId = _shopId;
    if (shopId == null) return;
    final key = _groupKey(group);
    setState(() {
      if (!_expandedGroups.remove(key)) {
        _expandedGroups.add(key);
        _groupProducts.putIfAbsent(
          key,
          () => group.type == ShopProductGrouping.brand
              ? _shopRepository.getShopProducts(
                  shopId: shopId,
                  brandId: group.id,
                  search: _search,
                )
              : _shopRepository.getShopProducts(
                  shopId: shopId,
                  viscosityId: group.viscosityFilter,
                  search: _search,
                ),
        );
      }
    });
  }

  void _retryGroup(ShopProductGroup group) {
    final key = _groupKey(group);
    setState(() {
      _groupProducts.remove(key);
      _expandedGroups.remove(key);
    });
    _toggleGroup(group);
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
        child: Column(
          children: [
            _buildModeChips(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _buildSearchField(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final mode in _ViewMode.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(mode.label),
                selected: _mode == mode,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _mode == mode ? Colors.white : AppColors.primary,
                ),
                onSelected: (_) => _selectMode(mode),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Поиск в магазине',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSearch,
                ),
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_shopId == null) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final emptyText = _search.isEmpty
        ? 'В этом магазине пока нет товаров'
        : 'Ничего не найдено';

    final groupsFuture = _groupsFuture;
    if (groupsFuture != null) {
      return FutureBuilder<List<ShopProductGroup>>(
        future: groupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildError('Не удалось загрузить товары магазина', _reload);
          }
          final groups = snapshot.data ?? const <ShopProductGroup>[];
          if (groups.isEmpty) {
            return Center(child: Text(emptyText));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildGroup(groups[index]),
          );
        },
      );
    }

    return FutureBuilder<List<OilItem>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildError('Не удалось загрузить товары магазина', _reload);
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(child: Text(emptyText));
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 16),
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

  Widget _buildError(String text, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }

  Widget _buildGroup(ShopProductGroup group) {
    final key = _groupKey(group);
    final expanded = _expandedGroups.contains(key);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggleGroup(group),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  _GroupLeading(group: group),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ассортимент: ${_positionsLabel(group.productsCount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: FutureBuilder<List<OilItem>>(
                future: _groupProducts[key],
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildError(
                        'Не удалось загрузить товары',
                        () => _retryGroup(group),
                      ),
                    );
                  }
                  final items = snapshot.data ?? const <OilItem>[];
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: Text('Нет товаров')),
                    );
                  }
                  return Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _ProductTile(
                            item: item,
                            shopId: _shopId,
                            shopRepository: _shopRepository,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// «1 позиция», «3 позиции», «12 позиций».
String _positionsLabel(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  final String word;
  if (mod10 == 1 && mod100 != 11) {
    word = 'позиция';
  } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    word = 'позиции';
  } else {
    word = 'позиций';
  }
  return '$count $word';
}

/// Логотип бренда или значок вязкости слева в заголовке группы.
class _GroupLeading extends StatelessWidget {
  final ShopProductGroup group;

  const _GroupLeading({required this.group});

  @override
  Widget build(BuildContext context) {
    final logo = group.logo;
    // SVG CachedNetworkImage не рисует — для таких брендов показываем букву
    final canShowLogo =
        logo.isNotEmpty &&
        !logo.toLowerCase().split('?').first.endsWith('.svg');

    return SizedBox(
      width: 64,
      height: 44,
      child: canShowLogo
          ? CachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.contain,
              placeholder: (context, url) => const SizedBox.shrink(),
              errorWidget: (context, url, error) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    final isViscosity = group.type == ShopProductGrouping.viscosity;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: isViscosity
          ? const Icon(Icons.water_drop_outlined, color: AppColors.primary)
          : Text(
              group.title.isNotEmpty ? group.title.characters.first : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
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
