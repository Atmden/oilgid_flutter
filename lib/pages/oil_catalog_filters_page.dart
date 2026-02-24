import 'dart:async';

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
  static const int _facetDebounceMs = 400;
  static const int _defaultFacetLimit = 50;
  static const int _expandAnimationMs = 240;
  static const Map<String, String> _facetTitleMap = {
    'brand': 'Бренд',
    'viscosity': 'Вязкость',
    'api': 'API',
    'acea': 'ACEA',
    'oem': 'OEM',
    'ilsac': 'ILSAC',
    'iso': 'ISO',
    'isovg': 'ISO VG',
    'jaso': 'JASO',
    'din': 'DIN',
    'parker_hannifin': 'Parker Hannifin',
    'part_number': 'Part Number',
  };

  late CatalogFilterState _state;
  final ScrollController _listScrollController = ScrollController();
  Map<String, List<CatalogFacetOption>> _facetItems = const {};
  Map<String, String> _facetSearch = {};
  final Map<String, bool> _facetLoading = {};
  final Map<String, String?> _facetError = {};
  final Map<String, TextEditingController> _facetControllers = {};
  final Map<String, GlobalKey> _facetSectionKeys = {};
  final Map<String, Timer> _facetDebounceTimers = {};
  int _totalMatched = 0;
  bool _loading = true;
  String? _error;
  int _lastRequestId = 0;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _facetSearch = Map<String, String>.from(_state.facetSearch);
    _loadFacets(showGlobalLoading: true);
  }

  @override
  void dispose() {
    for (final timer in _facetDebounceTimers.values) {
      timer.cancel();
    }
    for (final controller in _facetControllers.values) {
      controller.dispose();
    }
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFacets({
    String? localFacetKey,
    bool showGlobalLoading = false,
  }) async {
    final requestId = ++_lastRequestId;
    if (showGlobalLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (localFacetKey != null) {
      setState(() {
        _facetLoading[localFacetKey] = true;
        _facetError.remove(localFacetKey);
      });
    }

    try {
      final result = await AppApi().oilApi.getCatalogFacets(
        selectedFacetIds: _state.selectedFacetIds,
        facetSearch: _normalizedFacetSearch,
        facetLimit: _facetLimitMap,
        sort: _state.sort,
      );
      if (!mounted || requestId != _lastRequestId) return;

      setState(() {
        _facetItems = result.facets;
        _totalMatched = result.totalMatched;
        _loading = false;
        _error = null;
        for (final key in _facetLoading.keys) {
          _facetLoading[key] = false;
        }
        if (localFacetKey != null) {
          _facetError.remove(localFacetKey);
        }
      });
    } catch (e) {
      if (!mounted || requestId != _lastRequestId) return;
      setState(() {
        if (_facetItems.isEmpty || showGlobalLoading || localFacetKey == null) {
          _error = e.toString();
          _loading = false;
        }
        if (localFacetKey != null) {
          _facetLoading[localFacetKey] = false;
          _facetError[localFacetKey] = e.toString();
        }
      });
    }
  }

  Map<String, String> get _normalizedFacetSearch {
    final result = <String, String>{};
    _facetSearch.forEach((key, value) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        result[key] = normalized;
      }
    });
    return result;
  }

  Map<String, int> get _facetLimitMap {
    final keys = <String>{
      ...OilApi.defaultFacetKeys,
      ..._facetItems.keys,
      ..._facetSearch.keys,
      ..._state.selectedFacetIds.keys,
    };
    return {for (final key in keys) key: _defaultFacetLimit};
  }

  void _updateSelection({
    Map<String, List<int>>? selectedFacetIds,
    String? sort,
    bool clearSort = false,
    String? loadLocalFacetKey,
  }) {
    setState(() {
      _state = _state.copyWith(
        selectedFacetIds: selectedFacetIds,
        facetSearch: Map<String, String>.from(_facetSearch),
        sort: sort,
        clearSort: clearSort,
      );
    });
    _loadFacets(localFacetKey: loadLocalFacetKey);
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
    return _facetItems[key] ?? const [];
  }

  TextEditingController _controllerForFacet(String facetKey) {
    return _facetControllers.putIfAbsent(
      facetKey,
      () => TextEditingController(text: _facetSearch[facetKey] ?? ''),
    );
  }

  GlobalKey _sectionKeyForFacet(String facetKey) {
    return _facetSectionKeys.putIfAbsent(facetKey, () => GlobalKey());
  }

  void _scrollFacetHeaderToTop(String facetKey) {
    Future<void>.delayed(const Duration(milliseconds: _expandAnimationMs), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final context = _sectionKeyForFacet(facetKey).currentContext;
        if (context == null) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  void _onFacetSearchChanged(String facetKey, String value) {
    setState(() {
      _facetSearch[facetKey] = value;
      _state = _state.copyWith(
        facetSearch: Map<String, String>.from(_facetSearch),
      );
    });

    _facetDebounceTimers[facetKey]?.cancel();
    _facetDebounceTimers[facetKey] = Timer(
      const Duration(milliseconds: _facetDebounceMs),
      () {
        if (!mounted) return;
        _loadFacets(localFacetKey: facetKey);
      },
    );
  }

  List<String> _orderedFacetKeys() {
    final keys = <String>{
      ..._facetItems.keys,
      ..._state.selectedFacetIds.keys,
      ..._facetSearch.keys,
    };

    final ordered = <String>[];
    for (final known in OilApi.defaultFacetKeys) {
      if (keys.remove(known)) {
        ordered.add(known);
      }
    }

    final extra = keys.toList()..sort();
    ordered.addAll(extra);
    return ordered;
  }

  String _facetTitle(String facetKey) {
    final knownTitle = _facetTitleMap[facetKey];
    if (knownTitle != null) {
      return knownTitle;
    }
    return facetKey
        .split('_')
        .map((chunk) {
          if (chunk.isEmpty) return chunk;
          return '${chunk[0].toUpperCase()}${chunk.substring(1)}';
        })
        .join(' ');
  }

  List<int> _selectedIds(String facetKey) {
    return _state.selectedFacetIds[facetKey] ?? const [];
  }

  void _toggleFacetOption(String facetKey, int id) {
    final selectedFacetIds = <String, List<int>>{
      for (final entry in _state.selectedFacetIds.entries)
        entry.key: List<int>.from(entry.value),
    };
    final current = selectedFacetIds[facetKey] ?? const <int>[];
    final next = _toggleId(current, id);
    if (next.isEmpty) {
      selectedFacetIds.remove(facetKey);
    } else {
      selectedFacetIds[facetKey] = next;
    }

    _updateSelection(
      selectedFacetIds: selectedFacetIds,
      loadLocalFacetKey: facetKey,
    );
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
    if (_loading && _facetItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _facetItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить фасеты'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _loadFacets(showGlobalLoading: true),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    final facetKeys = _orderedFacetKeys();
    return Stack(
      children: [
        ListView(
          controller: _listScrollController,
          padding: const EdgeInsets.all(12),
          children: [
            _buildSortSection(),
            if (facetKeys.isEmpty)
              const Card(
                margin: EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Нет данных'),
                ),
              )
            else
              ...facetKeys.map(_buildDynamicFacetSection),
            const SizedBox(height: 80),
          ],
        ),
        if (_loading && _facetItems.isNotEmpty)
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
            const Text(
              'Сортировка',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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

  Widget _buildDynamicFacetSection(String facetKey) {
    final selected = _selectedIds(facetKey);
    final options = _group(facetKey);
    final searchValue = _facetSearch[facetKey] ?? '';
    final hasLocalError = _facetError[facetKey] != null;
    final isLoading = _facetLoading[facetKey] == true;
    final selectedSet = selected.toSet();

    return Card(
      key: _sectionKeyForFacet(facetKey),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: ValueKey<String>('facet_$facetKey'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text('${_facetTitle(facetKey)} (${selected.length})'),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        onExpansionChanged: (expanded) {
          if (expanded) {
            _scrollFacetHeaderToTop(facetKey);
          }
        },
        children: [
          TextField(
            controller: _controllerForFacet(facetKey),
            decoration: const InputDecoration(
              hintText: 'Поиск',
              isDense: true,
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            onChanged: (value) => _onFacetSearchChanged(facetKey, value),
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (hasLocalError)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ошибка загрузки'),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: () => _loadFacets(localFacetKey: facetKey),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          else if (options.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                searchValue.trim().isEmpty ? 'Нет данных' : 'Ничего не найдено',
              ),
            )
          else
            Column(
              children: options
                  .map(
                    (opt) => CheckboxListTile(
                      value: selectedSet.contains(opt.id),
                      onChanged: (_) => _toggleFacetOption(facetKey, opt.id),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(opt.title),
                      secondary: Text('${opt.count}'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  for (final timer in _facetDebounceTimers.values) {
                    timer.cancel();
                  }
                  Navigator.pop(
                    context,
                    const CatalogFilterState(
                      selectedFacetIds: {},
                      facetSearch: {},
                      sort: null,
                    ),
                  );
                },
                child: const Text('Сбросить'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(
                    context,
                    _state.copyWith(
                      facetSearch: Map<String, String>.from(_facetSearch),
                    ),
                  );
                },
                child: const Text('Применить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
