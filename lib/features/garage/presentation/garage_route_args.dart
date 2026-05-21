import '../domain/entities/service_record.dart';
import '../domain/entities/user_car.dart';

class GarageCarStatsArgs {
  final int carId;
  final String carDisplayName;
  final List<ServiceRecord> records;

  const GarageCarStatsArgs({
    required this.carId,
    required this.carDisplayName,
    required this.records,
  });
}

class GarageCarPageArgs {
  final int carId;
  final UserCar? car;

  const GarageCarPageArgs({required this.carId, this.car});
}

class GarageCarFormArgs {
  final UserCar? car;

  const GarageCarFormArgs({this.car});

  bool get isEdit => car != null;
}

class GarageServiceRecordPageArgs {
  final int recordId;
  final ServiceRecord? record;
  final String? carDisplayName;

  const GarageServiceRecordPageArgs({
    required this.recordId,
    this.record,
    this.carDisplayName,
  });
}

class GarageServiceRecordFormArgs {
  final int userCarId;
  final ServiceRecord? record;

  const GarageServiceRecordFormArgs({
    required this.userCarId,
    this.record,
  });

  bool get isEdit => record != null;
}
