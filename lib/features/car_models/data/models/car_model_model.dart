import '../../domain/entities/car_model.dart';

class CarModelModel extends CarModel {
  CarModelModel({
    required super.id,
    required super.name,
    required super.cyrillic_name,
    required super.year_from,
    required super.year_to,
  });

  factory CarModelModel.fromJson(Map<String, dynamic> json) {
    return CarModelModel(
      id: json['id'],
      name: json['name'],
      cyrillic_name: json['cyrillic_name'],
      year_from: json['year_from'],
      year_to: json['year_to'],
    );
  }
}
