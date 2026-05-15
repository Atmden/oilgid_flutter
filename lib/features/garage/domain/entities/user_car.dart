import 'modification_brief.dart';

class UserCar {
  final int id;
  final String? nickname;
  final String brand;
  final String model;
  final int? year;
  final String? vin;
  final String? plateNumber;
  final int? mileage;
  final int? modificationId;
  final ModificationBrief? modification;
  final String? markLogo;

  const UserCar({
    required this.id,
    this.nickname,
    required this.brand,
    required this.model,
    this.year,
    this.vin,
    this.plateNumber,
    this.mileage,
    this.modificationId,
    this.modification,
    this.markLogo,
  });

  String get displayName {
    final nick = nickname?.trim();
    if (nick != null && nick.isNotEmpty) return nick;
    final y = year != null ? ' $year' : '';
    return '$brand $model$y';
  }
}
