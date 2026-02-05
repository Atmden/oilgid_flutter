import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_type.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:oil_gid/themes/app_colors.dart';

class OilListPage extends StatefulWidget {
  const OilListPage({super.key});

  @override
  State<OilListPage> createState() => _OilListPageState();
}

class _OilListPageState extends State<OilListPage> {
  bool _initialized = false;
  int? _modificationId;
  int? _oilTypeId;
  String _oilTypeTitle = 'Масла';
  String _oilTypeVolume = '';
  String _oilTypeDescription = '';
  String? _carTitle;
  List<OilItem>? _items;
  Future<List<OilItem>>? _itemsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OilListArgs) {
      _modificationId = args.modificationId;
      _oilTypeId = args.oilTypeId;
      _oilTypeTitle = args.oilTypeTitle;
      _oilTypeVolume = args.oilTypeVolume;
      _oilTypeDescription = args.oilTypeDescription;
      _carTitle = args.carTitle;
      _items = args.items;
    }

    if (_items == null && _modificationId != null && _oilTypeId != null) {
      _itemsFuture = _fetchItems();
    }
  }

  Future<List<OilItem>> _fetchItems() async {
    final types = await AppApi()
        .oilApi
        .getOilsByModification(modificationId: _modificationId!);

    final matched = types.firstWhere(
      (type) => type.oilTypeId == _oilTypeId,
      orElse: () => OilType(
        oilTypeId: 0,
        oilTypeTitle: '',
        oilTypeIcon: '',
        oilTypeVolume: '',
        oilTypeDescription: '',
        items: const [],
      ),
    );

    return matched.items;
  }

  void _retryLoad() {
    if (_modificationId == null || _oilTypeId == null) return;
    setState(() {
      _itemsFuture = _fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(_oilTypeTitle),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_carTitle != null && _carTitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _carTitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Expanded(
                child: _buildListContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (_items != null) {
      return _buildList(_items!);
    }
    if (_itemsFuture == null) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    return FutureBuilder<List<OilItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Не удалось загрузить список масел'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _retryLoad,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }
        return _buildList(snapshot.data ?? []);
      },
    );
  }

  Widget _buildList(List<OilItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Список масел пуст'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final subtitleParts = <String>[];
        if (item.brandTitle.isNotEmpty) subtitleParts.add(item.brandTitle);
        if (item.viscosityTitle.isNotEmpty) {
          subtitleParts.add(item.viscosityTitle);
        }
        final subtitle = subtitleParts.join(' • ');

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            onTap: () {
              print(_oilTypeVolume);
              print(_oilTypeDescription);
              print(item);
              Navigator.pushNamed(
                context,
                '/oil_details',
                arguments: OilDetailsArgs(item: item, volume: _oilTypeVolume, description: _oilTypeDescription),
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
      },
    );
  }
}
