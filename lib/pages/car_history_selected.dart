import 'package:flutter/material.dart';
import 'package:oil_gid/includes/car_history_card.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/model/car_history_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CarHistorySelected extends StatefulWidget {
  const CarHistorySelected({super.key});

  @override
  State<CarHistorySelected> createState() => _CarHistorySelectedState();
}

class _CarHistorySelectedState extends State<CarHistorySelected> {
  final box = Hive.box('user_cars');

  List<dynamic> get history => box.values.toList().reversed.toList();

  void clearHistory() async {
    final box = Hive.box('user_cars');
    await box.clear();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: 'Выбранный автомобиль'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              OutlinedButton(
                onPressed: clearHistory,
                child: Text('Очистить историю выбранных автомобилей'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final raw = history[index];
                    final data = raw is Map ? raw : null;
                    if (data == null) {
                      return const SizedBox.shrink();
                    }
                    final item = CarHistoryModel.fromMap(data);
                    return CarHistoryCard(
                      item: item,
                      onDelete: () async {
                        await box.deleteAt(box.length - 1 - index);
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
