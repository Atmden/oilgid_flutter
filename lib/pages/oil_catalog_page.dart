import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/oils/data/datasources/oil_api.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:oil_gid/pages/oil_catalog_filters_page.dart';
import 'package:oil_gid/themes/app_colors.dart';

class OilCatalogPage extends StatefulWidget {
  const OilCatalogPage({super.key});

  @override
  State<OilCatalogPage> createState() => _OilCatalogPageState();
}

class _OilCatalogPageState extends State<OilCatalogPage> {
  final ScrollController _scrollController = ScrollController();
  final List<OilItem> _items = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  CatalogFilterState _filterState = const CatalogFilterState();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
    _items.clear();
    _currentPage = 1;
    _hasMore = true;
    await _loadFirstPage();
  }

  Future<void> _openFilters() async {
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
          children: [Expanded(child: _buildBody())],
        ),
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
      return const Center(
        child: Text('По выбранным фильтрам ничего не найдено'),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _OilCatalogTile(
          item: _items[index],
          onTap: () {
            Navigator.pushNamed(
              context,
              '/oil_details',
              arguments: OilDetailsArgs(
                item: _items[index],
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
