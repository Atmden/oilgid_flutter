import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:oil_gid/features/shops/domain/entities/shop.dart';
import 'package:oil_gid/features/shops/presentation/shop_route_args.dart';
import 'package:oil_gid/features/shops/presentation/widgets/shop_list_item.dart';
import 'package:oil_gid/themes/app_colors.dart';

class ShopsCatalogPage extends StatefulWidget {
  const ShopsCatalogPage({super.key});

  @override
  State<ShopsCatalogPage> createState() => _ShopsCatalogPageState();
}

class _ShopsCatalogPageState extends State<ShopsCatalogPage> {
  static const int _searchDebounceMs = 400;
  static const int _perPage = 20;

  final _shopRepository = ShopRepositoryImpl(AppApi().shopModelApi);
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  final List<Shop> _items = [];
  Timer? _searchDebounceTimer;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _sort = 'name';
  String? _search;
  double? _userLat;
  double? _userLng;
  String? _geoFallbackMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoading || _isLoadingMore) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= max - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final result = await _shopRepository.getShopsCatalog(
        page: 1,
        perPage: _perPage,
        search: _search,
        sort: _effectiveSort,
        lat: _effectiveLat,
        lng: _effectiveLng,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _currentPage = result.currentPage;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    try {
      final result = await _shopRepository.getShopsCatalog(
        page: nextPage,
        perPage: _perPage,
        search: _search,
        sort: _effectiveSort,
        lat: _effectiveLat,
        lng: _effectiveLng,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _currentPage = result.currentPage;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    await _ensureGeoForDistanceSort();
    await _loadFirstPage();
  }

  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () async {
        if (!mounted) return;
        final normalized = value.trim();
        final nextSearch = normalized.isEmpty ? null : normalized;
        if (nextSearch == _search) return;
        setState(() {
          _search = nextSearch;
        });
        await _loadFirstPage();
      },
    );
  }

  Future<void> _onSortChanged(String nextSort) async {
    if (nextSort == _sort) return;
    setState(() {
      _sort = nextSort;
      if (nextSort == 'name') {
        _geoFallbackMessage = null;
      }
    });

    await _ensureGeoForDistanceSort();
    await _loadFirstPage();
  }

  Future<void> _ensureGeoForDistanceSort() async {
    if (_sort != 'distance') {
      _userLat = null;
      _userLng = null;
      return;
    }

    final position = await _loadUserLocation();
    if (!mounted) return;
    if (position == null) {
      setState(() {
        _userLat = null;
        _userLng = null;
        _geoFallbackMessage =
            'Геолокация недоступна. Применена сортировка по названию.';
      });
      return;
    }

    setState(() {
      _userLat = position.latitude;
      _userLng = position.longitude;
      _geoFallbackMessage = null;
    });
  }

  Future<Position?> _loadUserLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  String get _effectiveSort {
    if (_sort == 'distance' && _userLat != null && _userLng != null) {
      return 'distance';
    }
    return 'name';
  }

  double? get _effectiveLat => _effectiveSort == 'distance' ? _userLat : null;
  double? get _effectiveLng => _effectiveSort == 'distance' ? _userLng : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Магазины'),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Поиск магазина',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      _onSearchChanged(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Сортировка'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sort,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'name',
                              child: Text('По названию'),
                            ),
                            DropdownMenuItem(
                              value: 'distance',
                              child: Text('По расстоянию'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            _onSortChanged(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_geoFallbackMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Text(
                        _geoFallbackMessage!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            const Center(child: Text('Не удалось загрузить магазины')),
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton(
                onPressed: _loadFirstPage,
                child: const Text('Повторить'),
              ),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Магазины не найдены')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final shop = _items[index];
          return ShopListItem(
            shop: shop,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/shop',
                arguments: ShopPageArgs(shop: shop),
              );
            },
          );
        },
      ),
    );
  }
}
