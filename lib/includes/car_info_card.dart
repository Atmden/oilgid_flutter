import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oil_gid/themes/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CarInfoCard extends StatelessWidget {
  const CarInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('user_cars');
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['selected_car']),
      builder: (context, box, _) {
        final raw = box.get('selected_car');
        final data = raw is Map ? raw : null;
        final hasData = data != null;

        final parts = <String>[];
        final mark = data?['mark_name'] as String?;
        final model = data?['model_name'] as String?;
        final generation = data?['generation_name'] as String?;
        final modification = data?['modification_name'] as String?;
        if (mark != null && mark.isNotEmpty) parts.add(mark);
        if (model != null && model.isNotEmpty) parts.add(model);
        if (generation != null && generation.isNotEmpty) parts.add(generation);
        
        if (modification != null && modification.isNotEmpty) {
          parts.add(modification);
        }
        final title = hasData && parts.isNotEmpty
            ? parts.join(' • ')
            : 'Автомобиль не выбран';

        void handleTap() {
          if (hasData) {
            Navigator.pushNamed(context, '/car_show_selected');
          } else {
            Navigator.pushNamed(context, '/car_select');
          }
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: handleTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 110),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 70,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(143, 255, 255, 255),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12),
                        ),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasData)
                          CachedNetworkImage(
                            imageUrl: data['mark_logo'] as String,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        if (!hasData)
                          const Icon(Icons.directions_car, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasData
                                    ? 'Выбранный автомобиль'
                                    : 'Автомобиль не выбран',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  decoration: hasData
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                  decorationColor: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasData
                                    ? 'Нажмите, чтобы открыть'
                                    : 'Нажмите, чтобы выбрать',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: handleTap,
                                  child: const Text('Выбрать другой'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
