import '../../domain/entities/oil_item.dart';
import '../../domain/repositories/oil_repository.dart';
import '../datasources/oil_api.dart';

class OilRepositoryImpl implements OilRepository {

  final OilApi api;

  OilRepositoryImpl(this.api);

  @override
  Future<OilItem> getOilById({required int oilId}) {
    return api.getOilById(oilId: oilId);
  }
 

}