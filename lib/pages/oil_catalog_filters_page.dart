import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/oils/data/datasources/oil_api.dart';
import 'package:oil_gid/themes/app_colors.dart';

class OilCatalogFiltersPage extends StatefulWidget {
  final CatalogFilterState initialState;

  const OilCatalogFiltersPage({super.key, required this.initialState});

  @override
  State<OilCatalogFiltersPage> createState() => _OilCatalogFiltersPageState();
}

class _OilCatalogFiltersPageState extends State<OilCatalogFiltersPage> {
  static const _sortOptions = <({String label, String value})>[
    (label: 'По названию', value: 'title'),
    (label: 'По бренду', value: 'brand_id'),
    (label: 'По вязкости', value: 'viscosity_id'),
    (label: 'Сначала новые', value: '-id'),
  ];

  late CatalogFilterState _state;
  Map<String, List<CatalogFacetOption>> _facets = const {};
  int _totalMatched = 0;
  bool _loading = true;
  String? _error;
  String _oemSearch = '';
  final TextEditingController _oemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _loadFacets();
  }

  @override
  void dispose() {
    _oemController.dispose();
    super.dispose();
  }

  Future<void> _loadFacets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AppApi().oilApi.getCatalogFacets(
            brandIds: _state.brandIds,
            viscosityIds: _state.viscosityIds,
            apiIds: _state.apiIds,
            aceaIds: _state.aceaIds,
            oemIds: _state.oemIds,
            ilsacIds: _state.ilsacIds,
            sort: _state.sort,
          );
      if (!mounted) return;
      setState(() {
        _facets = result.facets;
        _totalMatched = result.totalMatched;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _updateSelection({
    List<int>? brandIds,
    List<int>? viscosityIds,
    List<int>? apiIds,
    List<int>? aceaIds,
    List<int>? oemIds,
    List<int>? ilsacIds,
    String? sort,
    bool clearSort = false,
  }) {
    setState(() {
      _state = _state.copyWith(
        brandIds: brandIds,
        viscosityIds: viscosityIds,
        apiIds: apiIds,
        aceaIds: aceaIds,
        oemIds: oemIds,
        ilsacIds: ilsacIds,
        sort: sort,
        clearSort: clearSort,
      );
    });
    _loadFacets();
  }

  List<int> _toggleId(List<int> source, int id) {
    final next = List<int>.from(source);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    return next;
  }

  List<CatalogFacetOption> _group(String key) {
    return _facets[key] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Фильтры'),
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Найдено: $_totalMatched',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: _buildContent()),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _facets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _facets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить фасеты'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _loadFacets, child: const Text('Повторить')),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildSortSection(),
            _buildFacetSection(
              title: 'Бренд',
              options: _group('brand'),
              selected: _state.brandIds,
              onToggle: (id) => _updateSelection(
                brandIds: _toggleId(_state.brandIds, id),
              ),
            ),
            _buildFacetSection(
              title: 'Вязкость',
              options: _group('viscosity'),
              selected: _state.viscosityIds,
              onToggle: (id) => _updateSelection(
                viscosityIds: _toggleId(_state.viscosityIds, id),
              ),
            ),
            _buildFacetSection(
              title: 'API',
              options: _group('api'),
              selected: _state.apiIds,
              onToggle: (id) => _updateSelection(
                apiIds: _toggleId(_state.apiIds, id),
              ),
            ),
            _buildFacetSection(
              title: 'ACEA',
              options: _group('acea'),
              selected: _state.aceaIds,
              onToggle: (id) => _updateSelection(
                aceaIds: _toggleId(_state.aceaIds, id),
              ),
            ),
            _buildFacetSection(
              title: 'OEM',
              options: _group('oem')
                  .where((e) => e.title.toLowerCase().contains(_oemSearch.toLowerCase()))
                  .toList(),
              selected: _state.oemIds,
              onToggle: (id) => _updateSelection(
                oemIds: _toggleId(_state.oemIds, id),
              ),
              searchValue: _oemSearch,
              onSearchChanged: (value) => setState(() => _oemSearch = value),
            ),
            _buildFacetSection(
              title: 'ILSAC',
              options: _group('ilsac'),
              selected: _state.ilsacIds,
              onToggle: (id) => _updateSelection(
                ilsacIds: _toggleId(_state.ilsacIds, id),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
        if (_loading && _facets.isNotEmpty)
          const Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Widget _buildSortSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Сортировка', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Без сортировки'),
                  selected: _state.sort == null,
                  onSelected: (_) => _updateSelection(clearSort: true),
                ),
                ..._sortOptions.map(
                  (option) => ChoiceChip(
                    label: Text(option.label),
                    selected: _state.sort == option.value,
                    onSelected: (_) => _updateSelection(sort: option.value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacetSection({
    required String title,
    required List<CatalogFacetOption> options,
    required List<int> selected,
    required ValueChanged<int> onToggle,
    String? searchValue,
    ValueChanged<String>? onSearchChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text('$title (${selected.length})'),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        children: [
          if (onSearchChanged != null) ...[
            TextField(
              controller: _oemController,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Поиск',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                onSearchChanged(value);
              },
            ),
            const SizedBox(height: 8),
          ],
          if (options.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Нет данных'),
            )
          else
            ...options.map(
              (opt) => CheckboxListTile(
                value: selected.contains(opt.id),
                onChanged: (_) => onToggle(opt.id),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(opt.title),
                secondary: Text('${opt.count}'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _updateSelection(
                  brandIds: const [],
                  viscosityIds: const [],
                  apiIds: const [],
                  aceaIds: const [],
                  oemIds: const [],
                  ilsacIds: const [],
                  clearSort: true,
                );
              },
              child: const Text('Сбросить'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(context, _state),
              child: const Text('Применить'),
            ),
          ),
        ],
      ),
    );
  }
}

