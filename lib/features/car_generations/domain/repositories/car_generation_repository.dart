import '../entities/car_generation.dart';

abstract class CarGenerationRepository {
  Future<List<CarGeneration>> getCarGenerations({
    required int markId,
    required int modelId,
    String? search,
    int page = 1,
    int perPage = 25,
  });
}
