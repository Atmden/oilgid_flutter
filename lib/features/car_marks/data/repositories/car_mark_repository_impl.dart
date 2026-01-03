import '../../domain/entities/car_mark.dart';
import '../../domain/repositories/car_mark_repository.dart';
import '../datasources/car_mark_api.dart';

class CarMarkRepositoryImpl implements CarMarkRepository {
  final CarMarkApi api;

  CarMarkRepositoryImpl(this.api);

  @override
  Future<List<CarMark>> getCarMarks({
    String? search,
    int page = 1,
    int perPage = 25,
  }) {
    return api.getMarks(search: search, page: page, perPage: perPage);
  }

  @override
  // TODO: implement value
  get value => throw UnimplementedError();
}
