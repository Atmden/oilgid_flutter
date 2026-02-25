import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/oils/data/datasources/oil_api.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:oil_gid/features/oils/presentation/providers/oil_provider.dart';
import 'package:oil_gid/pages/oil_catalog_filters_page.dart';
import 'package:oil_gid/themes/app_colors.dart';

class OilCatalogPage extends ConsumerStatefulWidget {
  const OilCatalogPage({super.key});

  @override
  ConsumerState<OilCatalogPage> createState() => _OilCatalogPageState();
}

class _OilCatalogPageState extends ConsumerState<OilCatalogPage> {
  static const int _searchDebounceMs = 400;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<OilItem> _items = [];
  Timer? _searchDebounceTimer;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  CatalogFilterState _filterState = const CatalogFilterState();

  @override
  void initState() {
    super.initState();
    _searchController.text = _filterState.search ?? '';
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchFocusNode.unfocus();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _unfocusSearch() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  String? _normalizeSearch(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= max - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    if (_isLoading) return;
    setState(() {
      _error = null;
      _isLoading = true;
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    try {
      final result = await AppApi().oilApi.getOilsCatalog(
        page: 1,
        selectedFacetIds: _filterState.selectedFacetIds,
        sort: _filterState.sort,
        search: _filterState.search,
      );
      if (mounted) {
        setState(() {
          _items.addAll(result.items);
          _hasMore = result.hasMore;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    try {
      final result = await AppApi().oilApi.getOilsCatalog(
        page: nextPage,
        selectedFacetIds: _filterState.selectedFacetIds,
        sort: _filterState.sort,
        search: _filterState.search,
      );
      if (mounted) {
        setState(() {
          _items.addAll(result.items);
          _hasMore = result.hasMore;
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _applyFilters(CatalogFilterState nextState) async {
    if (!mounted) return;
    setState(() => _filterState = nextState);
    final nextSearch = nextState.search ?? '';
    if (_searchController.text != nextSearch) {
      _searchController.text = nextSearch;
      _searchController.selection = TextSelection.collapsed(
        offset: nextSearch.length,
      );
    }
    _items.clear();
    _currentPage = 1;
    _hasMore = true;
    await _loadFirstPage();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () async {
        if (!mounted) return;
        final nextSearch = _normalizeSearch(value);
        final currentSearch = _normalizeSearch(_filterState.search ?? '');
        if (nextSearch == currentSearch) return;

        setState(() {
          _filterState = _filterState.copyWith(
            search: nextSearch,
            clearSearch: nextSearch == null,
          );
        });
        await _loadFirstPage();
      },
    );
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty) return;
    _searchController.clear();
    _onSearchChanged('');
  }

  Future<void> _openFilters() async {
    _unfocusSearch();
    final result = await Navigator.push<CatalogFilterState>(
      context,
      MaterialPageRoute(
        builder: (_) => OilCatalogFiltersPage(initialState: _filterState),
      ),
    );
    if (result == null) return;
    await _applyFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Каталог масел'),
        actions: [
          TextButton.icon(
            onPressed: _openFilters,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune, color: Colors.white),
                if (_filterState.selectedFiltersCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_filterState.selectedFiltersCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: const Text('Фильтры', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_buildSearchField(), Expanded(child: _buildBody())],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Поиск масла по названию',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Очистить',
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close),
                ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          isDense: true,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Не удалось загрузить каталог',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _loadFirstPage();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      final hasSearch = _normalizeSearch(_filterState.search ?? '') != null;
      return Center(
        child: Text(
          hasSearch ? 'Ничего не найдено' : 'По выбранным фильтрам ничего не найдено',
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = _items[index];
        return _OilCatalogTile(
          item: item,
          onTap: () {
            _unfocusSearch();
            ref.read(selectedOilProvider.notifier).state = item;
            Navigator.pushNamed(
              context,
              '/oil_details',
              arguments: OilDetailsArgs(
                item: item,
                volume: '',
                description: '',
              ),
            );
          },
        );
      },
    );
  }
}

class _OilCatalogTile extends StatelessWidget {
  final OilItem item;
  final VoidCallback onTap;

  const _OilCatalogTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (item.brandTitle.isNotEmpty) subtitleParts.add(item.brandTitle);
    if (item.viscosityTitle.isNotEmpty) subtitleParts.add(item.viscosityTitle);
    final subtitle = subtitleParts.join(' • ');
    final previewUrl = item.images.isNotEmpty ? item.images.first : item.thumb;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
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
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }
}
