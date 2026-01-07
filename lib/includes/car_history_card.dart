import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oil_gid/themes/app_colors.dart';
import '../model/car_history_model.dart';

class CarHistoryCard extends StatelessWidget {
  final CarHistoryModel item;
  final VoidCallback? onDelete;

  const CarHistoryCard({super.key, required this.item, this.onDelete});

  String get title =>
      '${item.markName} ${item.modelName} ${item.generationName} ${item.modificationName}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => {},
      child: Container(
        constraints: const BoxConstraints(minHeight: 20),
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
                width: 55,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(143, 255, 255, 255),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Удалить из истории?'),
                            content: const Text(
                              'Вы уверены, что хотите удалить этот автомобиль из истории выбранных?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Удалить'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          onDelete?.call();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Colors.white60,
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          border: Border.all(color: Colors.white54, width: 0.5),
                          color: Colors.white24,
                        ),
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.markLogo,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),

                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 60),
                      Text(
                        'Нажмите, чтобы открыть',

                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
