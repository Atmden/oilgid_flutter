import '../entities/car_modification.dart';

abstract class CarModificationRepository {
  Future<List<CarModification>> getCarModifications({
    required int markId,
    required int modelId,
    required int generationId,
    required int configurationId,
    String? search,
    int page = 1,
    int perPage = 25,
  });
}
