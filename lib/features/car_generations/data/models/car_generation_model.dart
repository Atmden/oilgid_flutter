import '../../domain/entities/car_generation.dart';

class CarGenerationModel extends CarGeneration {
  CarGenerationModel({
    required super.id,
    required super.name,
    required super.year_from,
    required super.year_to,
  });

  factory CarGenerationModel.fromJson(Map<String, dynamic> json) {
    return CarGenerationModel(
      id: json['id'],
      name: json['name'],
      year_from: json['year_from'],
      year_to: json['year_to'],
    );
  }
}
