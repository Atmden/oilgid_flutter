import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:oil_gid/core/utils/yandex_map_utils.dart';
import 'package:oil_gid/features/shops/domain/entities/shop.dart';

class MapScreen extends StatefulWidget {
  final List<Shop> shops;
  const MapScreen({super.key, required this.shops});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapControllerCompleter = Completer<YandexMapController>();
  final Map<int, BitmapDescriptor> _clusterIconCache = {};
  static const int _clusterMinZoom = 13;
  static const double _clusterRadius = 60;

  @override
  void initState() {
    super.initState();
    _initPermission().ignore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Карта')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(8),
              child: YandexMap(
                mapObjects: [
                  ClusterizedPlacemarkCollection(
                    mapId: MapObjectId('shops_cluster'),
                    radius: _clusterRadius,
                    minZoom: _clusterMinZoom,
                    placemarks: widget.shops
                        .map(
                          (shop) => PlacemarkMapObject(
                            mapId: MapObjectId('shop_${shop.id}'),
                            point: Point(
                              latitude: shop.lat!,
                              longitude: shop.lng!,
                            ),
                            opacity: 1.0,
                            onTap: (_, __) => _showShopBottomSheet(shop),
                            icon: PlacemarkIcon.single(
                              PlacemarkIconStyle(
                                image: BitmapDescriptor.fromAssetImage(
                                  'assets/marker.png',
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onClusterAdded: (self, cluster) async {
                      final icon = await _getClusterIcon(cluster.size);
                      return cluster.copyWith(
                        appearance: cluster.appearance.copyWith(
                          icon: PlacemarkIcon.single(
                            PlacemarkIconStyle(
                              anchor: Offset(0.5, 0.5),
                              image: icon,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                onMapCreated: (controller) {
                  mapControllerCompleter.complete(controller);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initPermission() async {
    if (!await LocationServices().checkPermission()) {
      await LocationServices().requestPermission();
    }
    await _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    AppLatLong location;
    const defLocation = AqtobeLocation();
    try {
      location = await LocationServices().getCurrentLocation();
    } catch (_) {
      location = defLocation;
    }
    _moveToCurrentLocation(location);
  }

  Future<void> _moveToCurrentLocation(AppLatLong appLatLong) async {
    (await mapControllerCompleter.future).moveCamera(
      animation: const MapAnimation(type: MapAnimationType.linear, duration: 1),
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: appLatLong.lat, longitude: appLatLong.lng),
          zoom: 12,
        ),
      ),
    );
  }

  Future<BitmapDescriptor> _getClusterIcon(int size) async {
    final cached = _clusterIconCache[size];
    if (cached != null) return cached;

    const double iconSize = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFFE74C3C);

    canvas.drawCircle(
      const Offset(iconSize / 2, iconSize / 2),
      iconSize / 2,
      paint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: size.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (iconSize - textPainter.width) / 2,
        (iconSize - textPainter.height) / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      iconSize.toInt(),
      iconSize.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final bitmap = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    _clusterIconCache[size] = bitmap;
    return bitmap;
  }

  void _showShopBottomSheet(Shop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 16, bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _infoRow('Адрес', shop.address),
                        _infoRow('Телефон', shop.phone),
                        _infoRow('Email', shop.email),
                        _infoRow('Сайт', shop.website),
                        if (shop.price != null)
                          _infoRow('Цена', shop.price!.toStringAsFixed(2)),
                        if (shop.quantity != null)
                          _infoRow('Наличие', shop.quantity.toString()),
                        if (shop.distanceM != null)
                          _infoRow('Расстояние', '${shop.distanceM} м'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
