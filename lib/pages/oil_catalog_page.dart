import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/oils/data/datasources/oil_api.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
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

  int? _brandId;
  int? _viscosityId;
  String? _sort;

  List<CatalogFilterOption> _brandOptions = [];
  List<CatalogFilterOption> _viscosityOptions = [];
  bool _filtersLoading = true;
  bool _filtersExpanded = false;

  static const List<({String label, String? value})> _sortOptions = [
    (label: 'Без сортировки', value: null),
    (label: 'По названию', value: 'title'),
    (label: 'По бренду', value: 'brand_id'),
    (label: 'По вязкости', value: 'viscosity_id'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFilters();
    _loadFirstPage();
  }

  Future<void> _loadFilters() async {
    final api = AppApi().oilApi;
    try {
      final results = await Future.wait([
        api.getCatalogFilterBrands(),
        api.getCatalogFilterViscosities(),
      ]);
      if (mounted) {
        setState(() {
          _brandOptions = results[0];
          _viscosityOptions = results[1];
          _filtersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _filtersLoading = false);
    }
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
        brandId: _brandId,
        viscosityId: _viscosityId,
        sort: _sort,
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
        brandId: _brandId,
        viscosityId: _viscosityId,
        sort: _sort,
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

  void _onFilterOrSortChanged() {
    _items.clear();
    _currentPage = 1;
    _hasMore = true;
    _loadFirstPage();
  }

  void _resetFilters() {
    setState(() {
      _brandId = null;
      _viscosityId = null;
      _onFilterOrSortChanged();
    });
  }

  bool get _hasActiveFilters => _brandId != null || _viscosityId != null;

  List<({String label, int? value})> _filterOptionsWithAll(
      List<CatalogFilterOption> options) {
    final list = <({String label, int? value})>[(label: 'Все', value: null)];
    for (final o in options) {
      list.add((label: o.title, value: o.id));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Каталог масел'),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFiltersAndSort(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersAndSort() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Фильтры и сортировка',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 24,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          if (_filtersExpanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Сортировка:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _sort,
                      isExpanded: true,
                      hint: const Text('Выберите'),
                      items: _sortOptions
                          .map((e) => DropdownMenuItem<String?>(
                                value: e.value,
                                child: Text(e.label),
                              ))
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _sort = value;
                          _onFilterOrSortChanged();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FilterDropdown<int?>(
                    label: 'Бренд',
                    value: _brandId,
                    options: _filterOptionsWithAll(_brandOptions),
                    loading: _filtersLoading,
                    onChanged: (v) {
                      setState(() {
                        _brandId = v;
                        _onFilterOrSortChanged();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterDropdown<int?>(
                    label: 'Вязкость',
                    value: _viscosityId,
                    options: _filterOptionsWithAll(_viscosityOptions),
                    loading: _filtersLoading,
                    onChanged: (v) {
                      setState(() {
                        _viscosityId = v;
                        _onFilterOrSortChanged();
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Сбросить фильтры'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ],
        ],
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
              const Text('Не удалось загрузить каталог', textAlign: TextAlign.center),
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
              arguments: OilDetailsArgs(item: _items[index], volume: '', description: ''),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
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

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<({String label, T? value})> options;
  final bool loading;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    this.loading = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        DropdownButtonHideUnderline(
          child: DropdownButton<T?>(
            value: value,
            isExpanded: true,
            isDense: true,
            items: options
                .map((e) => DropdownMenuItem<T?>(
                    value: e.value,
                    child: Text(
                      e.label,
                      overflow: TextOverflow.ellipsis,
                    )))
                .toList(),
            onChanged: loading ? null : (T? v) => onChanged(v),
          ),
        ),
      ],
    );
  }
}
