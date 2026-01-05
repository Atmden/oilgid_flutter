import '../../domain/entities/car_configuration.dart';

class CarConfigurationModel extends CarConfiguration {
  CarConfigurationModel({
    required super.id,
    required super.name,
    required super.body_type,
    required super.doors_count,
  });

  factory CarConfigurationModel.fromJson(Map<String, dynamic> json) {
    return CarConfigurationModel(
      id: json['id'],
      name: json['name'],
      body_type: json['body_type'],
      doors_count: json['doors_count'],
    );
  }
}
