import '../entities/car_model.dart';

abstract class CarModelRepository {
  Future<List<CarModel>> getCarModels({
    required int markId,
    String? search,
    int page = 1,
    int perPage = 25,
  });
}
