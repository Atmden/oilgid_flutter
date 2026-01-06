import '../../domain/entities/car_modification.dart';

class CarModificationModel extends CarModification {
  CarModificationModel({
    required super.id,
    required super.name,
  });

  factory CarModificationModel.fromJson(Map<String, dynamic> json) {
    return CarModificationModel(
      id: json['id'],
      name: json['name'],
    );
  }
}
