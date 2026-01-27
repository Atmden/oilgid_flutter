import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/includes/NavigationDrawer.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/features/car_marks/domain/entities/car_mark.dart';
import 'package:oil_gid/features/car_models/domain/entities/car_model.dart';
import 'package:oil_gid/features/car_generations/domain/entities/car_generation.dart';
import 'package:oil_gid/features/car_configurations/domain/entities/car_configuration.dart';
import 'package:oil_gid/features/car_modifications/domain/entities/car_modification.dart';
import 'package:oil_gid/themes/default.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CarShowSelected extends StatefulWidget {
  const CarShowSelected({super.key});

  @override
  State<CarShowSelected> createState() => _CarShowSelectedState();
}

class _CarShowSelectedState extends State<CarShowSelected> {
  late CarMark selectedCarMark;
  late CarModel selectedCarModel;
  late CarGeneration selectedCarGeneration;
  late CarConfiguration selectedCarConfiguration;
  late CarModification selectedCarModification;
  @override
  void initState() {
    super.initState();

    final boxCars = Hive.box('user_cars');
    final selectedCar = boxCars.getAt(boxCars.length - 1) as Map;

    selectedCarMark = CarMark(
      id: selectedCar['mark_id'],
      name: selectedCar['mark_name'],
      cyrillic_name: selectedCar['mark_cyrillic_name'],
      year_from: selectedCar['mark_year_from'],
      year_to: selectedCar['mark_year_to'],
      country: selectedCar['mark_country'],
      logo: selectedCar['mark_logo'],
    );
    selectedCarModel = CarModel(
      id: selectedCar['model_id'],
      name: selectedCar['model_name'],
      cyrillic_name: selectedCar['model_cyrillic_name'],
      year_from: selectedCar['model_year_from'],
      year_to: selectedCar['model_year_to'],
    );
    selectedCarGeneration = CarGeneration(
      id: selectedCar['generation_id'],
      name: selectedCar['generation_name'],
      year_from: selectedCar['generation_year_from'],
      year_to: selectedCar['generation_year_to'],
    );
    selectedCarConfiguration = CarConfiguration(
      id: selectedCar['configuration_id'],
      name: selectedCar['configuration_name'],
      body_type: selectedCar['configuration_body_type'],
      doors_count: selectedCar['configuration_doors_count'],
      photo: selectedCar['configuration_photo'],
    );
    selectedCarModification = CarModification(
      id: selectedCar['modification_id'],
      name: selectedCar['modification_name'],
    );
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
                onPressed: () => {
                  Navigator.pushNamed(context, '/car_history_selected'),
                },
                child: Text('История выбора автомобиля'),
              ),
              CachedNetworkImage(
                imageUrl: selectedCarMark.logo,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
              Text('Выбранный автомобиль!'),
              Text('Марка: ${selectedCarMark.name}'),
              Text('Модель: ${selectedCarModel.name}'),
              Text('Генерация: ${selectedCarGeneration.name}'),
              Text('Конфигурация: ${selectedCarConfiguration.name}'),
              Text('Модификация: ${selectedCarModification.name}'),
            ],
          ),
        ),
      ),
    );
  }
}
