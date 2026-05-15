import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/car_configurations/domain/entities/car_configuration.dart';
import 'package:oil_gid/features/car_configurations/presentation/widgets/car_configuration_dropdown.dart';
import 'package:oil_gid/features/car_generations/domain/entities/car_generation.dart';
import 'package:oil_gid/features/car_generations/presentation/widgets/car_generation_dropdown.dart';
import 'package:oil_gid/features/car_marks/domain/entities/car_mark.dart';
import 'package:oil_gid/features/car_marks/presentation/widgets/car_mark_dropdown.dart';
import 'package:oil_gid/features/car_models/domain/entities/car_model.dart';
import 'package:oil_gid/features/car_models/presentation/widgets/car_model_dropdown.dart';
import 'package:oil_gid/features/car_modifications/domain/entities/car_modification.dart';
import 'package:oil_gid/features/car_modifications/presentation/widgets/car_modification_dropdown.dart';
import 'package:oil_gid/features/garage/presentation/garage_route_args.dart';
import 'package:oil_gid/themes/app_colors.dart';

class GarageCarFormPage extends ConsumerStatefulWidget {
  const GarageCarFormPage({super.key});

  @override
  ConsumerState<GarageCarFormPage> createState() => _GarageCarFormPageState();
}

class _GarageCarFormPageState extends ConsumerState<GarageCarFormPage> {
  final _garageApi = AppApi().garageApi;

  late GarageCarFormArgs _args;
  bool _initialized = false;

  bool _fromCatalog = true;

  CarMark? _mark;
  CarModel? _carModel;
  CarGeneration? _generation;
  CarConfiguration? _configuration;
  CarModification? _modification;

  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _vinController = TextEditingController();
  final _plateController = TextEditingController();
  final _mileageController = TextEditingController();

  bool _isSaving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _args = args is GarageCarFormArgs ? args : const GarageCarFormArgs();

    final car = _args.car;
    if (car != null) {
      _nicknameController.text = car.nickname ?? '';
      _vinController.text = car.vin ?? '';
      _plateController.text = car.plateNumber ?? '';
      _mileageController.text = car.mileage?.toString() ?? '';
      if (car.modificationId != null) {
        _fromCatalog = true;
      } else {
        _fromCatalog = false;
        _brandController.text = car.brand;
        _modelController.text = car.model;
        _yearController.text = car.year?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _nicknameController.dispose();
    _vinController.dispose();
    _plateController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final data = _buildPayload();
    if (data == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (_args.isEdit) {
        await _garageApi.updateCar(_args.car!.id, data);
      } else {
        await _garageApi.createCar(data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  Map<String, dynamic>? _buildPayload() {
    String brand;
    String model;
    int? year;
    int? modificationId;

    if (_fromCatalog) {
      if (_modification == null) {
        setState(() => _error = 'Выберите модификацию из каталога.');
        return null;
      }
      modificationId = _modification!.id;
      brand = _mark?.name ?? '';
      model = _carModel?.name ?? '';
    } else {
      brand = _brandController.text.trim();
      model = _modelController.text.trim();
      if (brand.isEmpty) {
        setState(() => _error = 'Введите марку автомобиля.');
        return null;
      }
      if (model.isEmpty) {
        setState(() => _error = 'Введите модель автомобиля.');
        return null;
      }
      year = int.tryParse(_yearController.text.trim());
    }

    return {
      if (modificationId != null) 'modification_id': modificationId,
      'brand': brand,
      'model': model,
      if (year != null) 'year': year,
      if (_nicknameController.text.trim().isNotEmpty)
        'nickname': _nicknameController.text.trim(),
      if (_vinController.text.trim().isNotEmpty)
        'vin': _vinController.text.trim(),
      if (_plateController.text.trim().isNotEmpty)
        'plate_number': _plateController.text.trim(),
      if (_mileageController.text.trim().isNotEmpty)
        'mileage': int.tryParse(_mileageController.text.trim()),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primarySoft,
        foregroundColor: Colors.white,
        title: Text(_args.isEdit ? 'Редактировать авто' : 'Добавить авто'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_args.isEdit) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeTab(
                          label: 'Из каталога',
                          selected: _fromCatalog,
                          onTap: () => setState(() {
                            _fromCatalog = true;
                            _error = null;
                          }),
                        ),
                      ),
                      Expanded(
                        child: _ModeTab(
                          label: 'Вручную',
                          selected: !_fromCatalog,
                          onTap: () => setState(() {
                            _fromCatalog = false;
                            _error = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_fromCatalog) ...[
                CarMarkDropdown(
                  value: _mark,
                  onChanged: (mark) => setState(() {
                    _mark = mark;
                    _carModel = null;
                    _generation = null;
                    _configuration = null;
                    _modification = null;
                  }),
                ),
                if (_mark != null) ...[
                  const SizedBox(height: 12),
                  CarModelDropdown(
                    value: _carModel,
                    markId: _mark!.id,
                    onChanged: (m) => setState(() {
                      _carModel = m;
                      _generation = null;
                      _configuration = null;
                      _modification = null;
                    }),
                  ),
                ],
                if (_carModel != null) ...[
                  const SizedBox(height: 12),
                  CarGenerationDropdown(
                    value: _generation,
                    markId: _mark!.id,
                    modelId: _carModel!.id,
                    onChanged: (g) => setState(() {
                      _generation = g;
                      _configuration = null;
                      _modification = null;
                    }),
                  ),
                ],
                if (_generation != null) ...[
                  const SizedBox(height: 12),
                  CarConfigurationDropdown(
                    value: _configuration,
                    markId: _mark!.id,
                    modelId: _carModel!.id,
                    generationId: _generation!.id,
                    onChanged: (c) => setState(() {
                      _configuration = c;
                      _modification = null;
                    }),
                  ),
                ],
                if (_configuration != null) ...[
                  const SizedBox(height: 12),
                  CarModificationDropdown(
                    value: _modification,
                    markId: _mark!.id,
                    modelId: _carModel!.id,
                    generationId: _generation!.id,
                    configurationId: _configuration!.id,
                    onChanged: (mod) => setState(() => _modification = mod),
                  ),
                ],
              ] else ...[
                TextField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    labelText: 'Марка *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Модель *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Год выпуска',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const _SectionTitle('Дополнительно'),
              const SizedBox(height: 12),

              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Название (псевдоним)',
                  hintText: 'Например: Моя ласточка',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vinController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'VIN',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Гос. номер',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Пробег (км)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_args.isEdit ? 'Сохранить' : 'Добавить'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}
