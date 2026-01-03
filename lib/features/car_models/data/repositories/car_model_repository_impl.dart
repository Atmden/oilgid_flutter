import '../../domain/entities/car_model.dart';
import '../../domain/repositories/car_model_repository.dart';
import '../datasources/car_model_api.dart';

class CarModelRepositoryImpl implements CarModelRepository {
  final CarModelApi api;

  CarModelRepositoryImpl(this.api);

  @override
  Future<List<CarModel>> getCarModels({
    required int markId,
    String? search,
    int page = 1,
    int perPage = 25,
  }) {
    return api.getModels(markId: markId, search: search, page: page, perPage: perPage);
  }
}
