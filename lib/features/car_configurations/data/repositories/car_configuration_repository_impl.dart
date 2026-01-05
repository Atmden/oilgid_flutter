import '../../domain/entities/car_configuration.dart';
import '../../domain/repositories/car_configuration_repository.dart';
import '../datasources/car_configuration_api.dart';

class CarConfigurationRepositoryImpl implements CarConfigurationRepository {
  final CarConfigurationApi api;

  CarConfigurationRepositoryImpl(this.api);

  @override
  Future<List<CarConfiguration>> getCarConfigurations({
    required int markId,
    required int modelId,
    required int generationId,
    String? search,
    int page = 1,
    int perPage = 25,
  }) {
    return api.getConfigurations(
      markId: markId,
      modelId: modelId,
      generationId: generationId,
      search: search,
      page: page,
      perPage: perPage,
    );
  }
}
