import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_type.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/themes/app_colors.dart';

class CarShowSelected extends StatefulWidget {
  const CarShowSelected({super.key});

  @override
  State<CarShowSelected> createState() => _CarShowSelectedState();
}

class _CarShowSelectedState extends State<CarShowSelected> {
  bool _initialized = false;
  int? _modificationId;
  String? _carTitle;
  String? _carSubtitle;
  String? _carLogo;
  Future<List<OilType>>? _oilTypesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OilSelectionArgs) {
      _modificationId = args.modificationId;
      _carTitle = args.carTitle;
      _carSubtitle = args.carSubtitle;
      _carLogo = args.carLogo;
    }

    if (_modificationId == null) {
      final fallback = _readCarFromHive();
      if (fallback != null) {
        _applyCarDataFromMap(fallback);
      }
    }

    if (_modificationId != null) {
      _oilTypesFuture = _fetchOilTypes();
    }
  }

  Future<List<OilType>> _fetchOilTypes() {
    return AppApi().oilApi.getOilsByModification(
          modificationId: _modificationId!,
        );
  }

  Map<String, dynamic>? _readCarFromHive() {
    final boxCars = Hive.box('user_cars');
    if (boxCars.isEmpty) return null;
    final selectedCar = boxCars.getAt(boxCars.length - 1);
    return selectedCar is Map ? Map<String, dynamic>.from(selectedCar) : null;
  }

  void _applyCarDataFromMap(Map<String, dynamic> selectedCar) {
    _modificationId = selectedCar['modification_id'];
    _carLogo = selectedCar['mark_logo'];
    _carTitle = _buildCarTitle(selectedCar);
    _carSubtitle = selectedCar['configuration_name'];
  }

  String _buildCarTitle(Map<String, dynamic> data) {
    final parts = <String>[];
    final mark = data['mark_name'] as String?;
    final model = data['model_name'] as String?;
    final generation = data['generation_name'] as String?;
    final modification = data['modification_name'] as String?;
    if (mark != null && mark.isNotEmpty) parts.add(mark);
    if (model != null && model.isNotEmpty) parts.add(model);
    if (generation != null && generation.isNotEmpty) parts.add(generation);
    if (modification != null && modification.isNotEmpty) parts.add(modification);
    return parts.join(' ');
  }

  void _retryLoad() {
    if (_modificationId == null) return;
    setState(() {
      _oilTypesFuture = _fetchOilTypes();
    });
  }

  void _openHistory() {
    Navigator.pushNamed(context, '/car_history_selected');
  }

  void _openCarSelect() {
    Navigator.pushNamed(context, '/car_select');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Подбор масел'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _openHistory,
                    child: const Text('История выбора'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _openCarSelect,
                    child: const Text('Выбрать авто'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCarCard(),
              const SizedBox(height: 16),
              const Text(
                'Выберите тип масла',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildOilTypesContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarCard() {
    final title = _carTitle?.isNotEmpty == true
        ? _carTitle!
        : 'Автомобиль не выбран';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _carLogo?.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: _carLogo!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const SizedBox(width: 24, height: 24),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.directions_car,
                      color: Colors.white70,
                      size: 32,
                    ),
                  )
                : const Icon(
                    Icons.directions_car,
                    color: Colors.white70,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_carSubtitle != null && _carSubtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _carSubtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOilTypesContent() {
    if (_modificationId == null || _oilTypesFuture == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Сначала выберите автомобиль'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _openCarSelect,
              child: const Text('Выбрать автомобиль'),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<OilType>>(
      future: _oilTypesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Не удалось загрузить типы масел'),
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
          return const Center(
            child: Text('Для этого автомобиля пока нет масел'),
          );
        }

        return GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final type = items[index];
            return _OilTypeTile(
              type: type,
              carTitle: _carTitle,
              modificationId: _modificationId!,
            );
          },
        );
      },
    );
  }
}

class _OilTypeTile extends StatelessWidget {
  final OilType type;
  final int modificationId;
  final String? carTitle;

  const _OilTypeTile({
    required this.type,
    required this.modificationId,
    required this.carTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          print(type);
          Navigator.pushNamed(
            context,
            '/oil_list',
            arguments: OilListArgs(
              modificationId: modificationId,
              oilTypeId: type.oilTypeId,
              oilTypeTitle: type.oilTypeTitle,
              oilTypeVolume: type.oilTypeVolume,
              oilTypeDescription: type.oilTypeDescription,
              carTitle: carTitle,
              items: type.items,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (type.oilTypeIcon.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: type.oilTypeIcon,
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const SizedBox(width: 24, height: 24),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.oil_barrel,
                    size: 28,
                    color: Colors.black54,
                  ),
                ),
              if (type.oilTypeIcon.isNotEmpty) const SizedBox(height: 10),
              Text(
                type.oilTypeTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Вариантов: ${type.items.length}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
