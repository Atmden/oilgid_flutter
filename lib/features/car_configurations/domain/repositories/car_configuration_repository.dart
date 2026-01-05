import '../entities/car_configuration.dart';

abstract class CarConfigurationRepository {
  Future<List<CarConfiguration>> getCarConfigurations({
    required int markId,
    required int modelId,
    required int generationId,
    String? search,
    int page = 1,
    int perPage = 25,
  });
}
