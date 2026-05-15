import '../../../../core/utils/parsers.dart';
import '../../domain/entities/modification_brief.dart';
import '../../domain/entities/user_car.dart';

class ModificationBriefModel extends ModificationBrief {
  const ModificationBriefModel({
    required super.id,
    required super.name,
    required super.mark,
    required super.model,
    super.generation,
  });

  factory ModificationBriefModel.fromJson(Map<String, dynamic> json) {
    return ModificationBriefModel(
      id: toIntSafe(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      mark: json['mark']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      generation: json['generation']?.toString(),
    );
  }
}

class UserCarModel extends UserCar {
  const UserCarModel({
    required super.id,
    super.nickname,
    required super.brand,
    required super.model,
    super.year,
    super.vin,
    super.plateNumber,
    super.mileage,
    super.modificationId,
    super.modification,
    super.markLogo,
  });

  factory UserCarModel.fromJson(Map<String, dynamic> json) {
    final modJson = json['modification'];
    return UserCarModel(
      id: toIntSafe(json['id']) ?? 0,
      nickname: json['nickname']?.toString(),
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: toIntSafe(json['year']),
      vin: json['vin']?.toString(),
      plateNumber: json['plate_number']?.toString(),
      mileage: toIntSafe(json['mileage']),
      modificationId: toIntSafe(json['modification_id']),
      modification: modJson is Map<String, dynamic>
          ? ModificationBriefModel.fromJson(modJson)
          : null,
      markLogo: json['mark_logo']?.toString(),
    );
  }
}
