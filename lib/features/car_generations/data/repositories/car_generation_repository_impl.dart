import '../../domain/entities/car_generation.dart';
import '../../domain/repositories/car_generation_repository.dart';
import '../datasources/car_generation_api.dart';

class CarGenerationRepositoryImpl implements CarGenerationRepository {
  final CarGenerationApi api;

  CarGenerationRepositoryImpl(this.api);

  @override
  Future<List<CarGeneration>> getCarGenerations({
    required int markId,
    required int modelId,
    String? search,
    int page = 1,
    int perPage = 25,
  }) {
    return api.getGenerations(markId: markId, modelId: modelId, search: search, page: page, perPage: perPage);
  }
}
