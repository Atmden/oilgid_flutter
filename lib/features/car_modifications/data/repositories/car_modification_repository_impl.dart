import '../../domain/entities/car_modification.dart';
import '../../domain/repositories/car_modification_repository.dart';
import '../datasources/car_modification_api.dart';

class CarModificationRepositoryImpl implements CarModificationRepository {
  final CarModificationApi api;

  CarModificationRepositoryImpl(this.api);

  @override
  Future<List<CarModification>> getCarModifications({
    required int markId,
    required int modelId,
    required int generationId,
    required int configurationId,
    String? search,
    int page = 1,
    int perPage = 25,
  }) {
    return api.getModifications(
      markId: markId,
      modelId: modelId,
      generationId: generationId,
      configurationId: configurationId,
      search: search,
      page: page,
      perPage: perPage,
    );
  }
}
