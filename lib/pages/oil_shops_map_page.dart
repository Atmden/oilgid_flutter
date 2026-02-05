import 'package:flutter/material.dart';
import 'package:oil_gid/features/shops/domain/entities/shop.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class OilShopsMapPage extends StatelessWidget {
  final List<Shop> shops;
  final double? userLat;
  final double? userLng;

  const OilShopsMapPage({
    super.key,
    required this.shops,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Магазины на карте')),
      body: YandexMap(
        onMapCreated: (controller) async {
          // можно сместить камеру на пользователя или на первый магазин
        },
        mapObjects: shops
            .where((s) => s.lat != null && s.lng != null)
            .map((shop) => PlacemarkMapObject(
                  mapId: MapObjectId('shop_${shop.id}'),
                  point: Point(latitude: shop.lat!, longitude: shop.lng!),
                  icon: PlacemarkIcon.single(
                    PlacemarkIconStyle(
                      image: BitmapDescriptor.fromAssetImage(
                        'assets/marker.png',
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}