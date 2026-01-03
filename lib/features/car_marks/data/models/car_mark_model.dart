import '../../domain/entities/car_mark.dart';

class CarMarkModel extends CarMark {
  CarMarkModel({
    required super.id,
    required super.name,
    required super.cyrillic_name,
    required super.year_from,
    required super.year_to,
    required super.country,
    required super.logo,
  });

  factory CarMarkModel.fromJson(Map<String, dynamic> json) {
    return CarMarkModel(
      id: json['id'],
      name: json['name'],
      cyrillic_name: json['cyrillic_name'],
      year_from: json['year_from'],
      year_to: json['year_to'],
      country: json['country'],
      logo: json['logo'],
    );
  }
}
