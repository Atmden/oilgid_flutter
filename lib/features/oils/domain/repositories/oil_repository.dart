import '../entities/oil_item.dart';

abstract class OilRepository {
  Future<OilItem> getOilById({required int oilId});
}