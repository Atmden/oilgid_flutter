import '../entities/car_mark.dart';

abstract class CarMarkRepository {
  get value => null;

  Future<List<CarMark>> getCarMarks({
    String? search,
    int page = 1,
    int perPage = 25,
  });
}
