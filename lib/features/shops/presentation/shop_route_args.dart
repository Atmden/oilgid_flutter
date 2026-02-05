import '../domain/entities/shop.dart';

class OilShopsMapArgs {
  final List<Shop> shops;
  final double? userLat;
  final double? userLng;

  OilShopsMapArgs({required this.shops, this.userLat, this.userLng});
}