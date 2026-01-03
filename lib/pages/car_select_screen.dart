import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/features/car_marks/domain/entities/car_mark.dart';
import 'package:oil_gid/features/car_marks/presentation/widgets/car_mark_dropdown.dart';
import 'package:oil_gid/themes/app_colors.dart';

import '../features/car_models/domain/entities/car_model.dart';
import '../features/car_models/presentation/widgets/car_model_dropdown.dart';
import '../features/car_generations/domain/entities/car_generation.dart';
import '../features/car_generations/presentation/widgets/car_generation_dropdown.dart';

class CarSelectScreen extends StatefulWidget {
  const CarSelectScreen({super.key});

  @override
  State<CarSelectScreen> createState() => _CarSelectScreenState();
}

class _CarSelectScreenState extends State<CarSelectScreen> {
  CarMark? selectedCarMark;
  CarModel? selectedCarModel;
  CarGeneration? selectedCarGeneration;


  

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
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 80,
                    width: 80,
                    child: Builder(
                      builder: (_) {
                        final logo = selectedCarMark?.logo ?? '';
                        if (logo.isEmpty) {
                          return const DecoratedBox(
                            decoration: BoxDecoration(color: Colors.black12),
                            child: Icon(Icons.directions_car, size: 32, color: Colors.grey),
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
                          errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported),
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
                  });
                },
              ),
              
              const SizedBox(height: 16),
              if (selectedCarMark != null)
                CarModelDropdown(
                  markId: selectedCarMark!.id,
                  value: selectedCarModel,
                  onChanged: (model) {
                    setState(() {
                      selectedCarModel = model;
                      selectedCarGeneration = null;
                    });
                  },
                ),
              if (selectedCarModel != null)
                CarGenerationDropdown(
                  markId: selectedCarMark!.id,
                  modelId: selectedCarModel!.id,
                  value: selectedCarGeneration,
                  onChanged: (generation) {
                    setState(() {
                      selectedCarGeneration = generation;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
