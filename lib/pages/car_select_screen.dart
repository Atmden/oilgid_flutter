import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oil_gid/features/car_marks/domain/entities/car_mark.dart';
import 'package:oil_gid/features/car_marks/presentation/widgets/car_mark_dropdown.dart';
import 'package:oil_gid/themes/app_colors.dart';

import '../features/car_modifications/domain/entities/car_modification.dart';
import '../features/car_models/domain/entities/car_model.dart';
import '../features/car_models/presentation/widgets/car_model_dropdown.dart';
import '../features/car_generations/domain/entities/car_generation.dart';
import '../features/car_configurations/domain/entities/car_configuration.dart';
import '../features/car_generations/presentation/widgets/car_generation_dropdown.dart';
import '../features/car_configurations/presentation/widgets/car_configuration_dropdown.dart';
import '../features/car_modifications/presentation/widgets/car_modification_dropdown.dart';

class CarSelectScreen extends StatefulWidget {
  const CarSelectScreen({super.key});

  @override
  State<CarSelectScreen> createState() => _CarSelectScreenState();
}

class _CarSelectScreenState extends State<CarSelectScreen> {
  CarMark? selectedCarMark;
  CarModel? selectedCarModel;
  CarGeneration? selectedCarGeneration;
  CarConfiguration? selectedCarConfiguration;
  CarModification? selectedCarModification;
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Выбор автомобиля'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Фиксированное место под логотип: всегда есть в дереве, меняется только url
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(150),
                  child: SizedBox(
                    height: 120,
                    width: 120,
                    child: Builder(
                      builder: (_) {
                        final logo = selectedCarMark?.logo ?? '';
                        if (logo.isEmpty) {
                          return const DecoratedBox(
                            decoration: BoxDecoration(color: Colors.black12),
                            child: Icon(
                              Icons.directions_car,
                              size: 32,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return CachedNetworkImage(
                          imageUrl: logo,
                          fit: BoxFit.cover,
                          memCacheWidth: 160,
                          memCacheHeight: 160,
                          filterQuality: FilterQuality.low,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          progressIndicatorBuilder: (_, __, progress) => Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: progress.progress,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CarMarkDropdown(
                value: selectedCarMark,
                onChanged: (mark) {
                  setState(() {
                    selectedCarMark = mark;
                    selectedCarModel = null;
                    selectedCarGeneration = null;
                    selectedCarConfiguration = null;
                    selectedCarModification = null;
                  });
                },
              ),

              const SizedBox(height: 16),
              if (selectedCarMark != null && selectedCarMark!.id != null)
                CarModelDropdown(
                  markId: selectedCarMark!.id,
                  value: selectedCarModel,
                  onChanged: (model) {
                    setState(() {
                      selectedCarModel = model;
                      selectedCarGeneration = null;
                      selectedCarConfiguration = null;
                      selectedCarModification = null;
                    });
                  },
                ),
              const SizedBox(height: 16),
              if (selectedCarModel != null)
                CarGenerationDropdown(
                  markId: selectedCarMark!.id,
                  modelId: selectedCarModel!.id,
                  value: selectedCarGeneration,
                  onChanged: (generation) {
                    setState(() {
                      selectedCarGeneration = generation;
                      selectedCarConfiguration = null;
                      selectedCarModification = null;
                    });
                  },
                ),
              const SizedBox(height: 16),
              if (selectedCarGeneration != null)
                CarConfigurationDropdown(
                  markId: selectedCarMark!.id,
                  modelId: selectedCarModel!.id,
                  generationId: selectedCarGeneration!.id,
                  value: selectedCarConfiguration,
                  onChanged: (configuration) {
                    setState(() {
                      selectedCarConfiguration = configuration;
                      selectedCarModification = null;
                    });
                  },
                ),
              const SizedBox(height: 16),
              if (selectedCarConfiguration != null)
                CarModificationDropdown(
                  markId: selectedCarMark!.id,
                  modelId: selectedCarModel!.id,
                  generationId: selectedCarGeneration!.id,
                  configurationId: selectedCarConfiguration!.id,
                  value: selectedCarModification,
                  onChanged: (modification) {
                    setState(() {
                      selectedCarModification = modification;
                    });
                  },
                ),
              const Spacer(),
              if (selectedCarModification != null)
                Center(
                  child: FilledButton(
                    onPressed: () async {
                      setState(() {
                        loading = true;
                      });
                      await _saveCarSelection(
                        selectedCarMark: selectedCarMark!,
                        selectedCarModel: selectedCarModel!,
                        selectedCarGeneration: selectedCarGeneration!,
                        selectedCarConfiguration: selectedCarConfiguration!,
                        selectedCarModification: selectedCarModification!,
                      );
                      setState(() {
                        loading = false;
                      });
                      Navigator.pushNamed(context, '/car_show_selected');
                    },
                    child: loading ? const CircularProgressIndicator() : const Text('Сохранить выбор'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _saveCarSelection({
  required CarMark selectedCarMark,
  required CarModel selectedCarModel,
  required CarGeneration selectedCarGeneration,
  required CarConfiguration selectedCarConfiguration,
  required CarModification selectedCarModification,
}) async {
  final box = Hive.box('user_cars');
  await box.put('selected_car', {
    'mark_id': selectedCarMark.id,
    'mark_name': selectedCarMark.name,
    'mark_cyrillic_name': selectedCarMark.cyrillic_name,
    'mark_year_from': selectedCarMark.year_from,
    'mark_year_to': selectedCarMark.year_to,
    'mark_country': selectedCarMark.country,
    'mark_logo': selectedCarMark.logo,
    'model_id': selectedCarModel.id,
    'model_name': selectedCarModel.name,
    'model_cyrillic_name': selectedCarModel.cyrillic_name,
    'model_year_from': selectedCarModel.year_from,
    'model_year_to': selectedCarModel.year_to,
    'generation_id': selectedCarGeneration.id,
    'generation_name': selectedCarGeneration.name,
    'generation_year_from': selectedCarGeneration.year_from,
    'generation_year_to': selectedCarGeneration.year_to,
    'configuration_id': selectedCarConfiguration.id,
    'configuration_name': selectedCarConfiguration.name,
    'configuration_body_type': selectedCarConfiguration.body_type,
    'configuration_doors_count': selectedCarConfiguration.doors_count,
    'modification_id': selectedCarModification.id,
    'modification_name': selectedCarModification.name,
  });
}
