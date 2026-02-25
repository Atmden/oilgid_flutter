import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/utils/navigation_launcher.dart';
import 'package:oil_gid/core/utils/yandex_map_utils.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/oils/presentation/providers/oil_provider.dart';
import 'package:oil_gid/features/oils/presentation/widgets/oil_gallery.dart';
import 'package:oil_gid/features/shops/domain/entities/shop.dart';
import 'package:oil_gid/features/shops/presentation/shop_route_args.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:oil_gid/features/oils/presentation/widgets/oil_approvals_group.dart';

class MapScreen extends ConsumerStatefulWidget {
  final List<Shop> shops;

  const MapScreen({super.key, required this.shops});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
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
      appBar: AppBar(title: const Text('Карта')),
      body: YandexMap(
        mapObjects: [
          ClusterizedPlacemarkCollection(
            mapId: const MapObjectId('shops_cluster'),
            radius: _clusterRadius,
            minZoom: _clusterMinZoom,
            placemarks: widget.shops
                .where((shop) => shop.lat != null && shop.lng != null)
                .map(
                  (shop) => PlacemarkMapObject(
                    mapId: MapObjectId('shop_${shop.id}'),
                    point: Point(latitude: shop.lat!, longitude: shop.lng!),
                    opacity: 1,
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
                      anchor: const Offset(0.5, 0.5),
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
    );
  }

  // ---------------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Cluster icon
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Bottom sheet
  // ---------------------------------------------------------------------------

  void _showShopBottomSheet(Shop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              final product = ref.watch(selectedOilProvider);
              final images = product?.resolveImages() ?? [];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _infoRow('Адрес', shop.address, 'address'),
                    _infoRow('Телефон', shop.phone, 'phone'),
                    _infoRow('Email', shop.email, 'email'),
                    _infoRow('Сайт', shop.website, 'website'),

                    if (shop.price != null)
                      _infoRow('Цена', shop.price!.toStringAsFixed(2), 'price'),

                    if (shop.quantity != null)
                      _infoRow('Наличие', shop.quantity.toString(), 'quantity'),

                    if (shop.distanceM != null)
                      _infoRow('Расстояние', '${shop.distanceM} м', 'distance'),

                    Column(
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          'Товар который вы смотрели',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product?.title ?? 'Нет данных',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OilGallery(images: images),
                        const SizedBox(height: 8),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          'Характеристики',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InfoRow(
                          label: 'Бренд',
                          value: product?.brandTitle ?? '',
                        ),
                        InfoRow(
                          label: 'Вязкость',
                          value: product?.viscosityTitle ?? '',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Допуски',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (product?.specification != null)
                          ApprovalsGroup(
                            title: 'ACEA',
                            values: product!.specification!.aceas,
                          ),
                        if (product?.specification != null)
                          ApprovalsGroup(
                            title: 'API',
                            values: product!.specification!.apis,
                          ),
                        if (product?.specification != null)
                          ApprovalsGroup(
                            title: 'OEM',
                            values: product!.specification!.oemApprovals,
                          ),
                        if (product?.specification != null)
                          ApprovalsGroup(
                            title: 'ILSAC',
                            values: product!.specification!.ilsacs,
                          ),
                        const SizedBox(height: 12),
                        if (product?.description != null)
                          const Text(
                            'Описание',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (product?.description != null)
                          Text(
                            product!.description,
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.justify,
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),

                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: NavigationLauncher.canBuildRoute(
                            lat: shop.lat,
                            lng: shop.lng,
                            address: shop.address,
                          )
                          ? () => NavigationLauncher.openRoute(
                                context: this.context,
                                shopName: shop.name,
                                lat: shop.lat,
                                lng: shop.lng,
                                address: shop.address,
                              )
                          : null,
                      child: const Text('Проложить маршрут'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(this.context).pushNamed(
                          '/shop',
                          arguments: ShopPageArgs(shop: shop),
                        );
                      },
                      child: const Text('Открыть магазин'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Info row
  // ---------------------------------------------------------------------------

  Widget _infoRow(String label, String? value, String? type) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    void open(String uri) => launchUrl(Uri.parse(uri));

    Widget row(Widget child) {
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
            Expanded(child: child),
          ],
        ),
      );
    }

    switch (type) {
      case 'phone':
        final phone = value.replaceAll(' ', '');
        return row(
          GestureDetector(
            onTap: () => open('tel:$phone'),
            child: Text(
              phone,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );

      case 'email':
        return row(
          GestureDetector(
            onTap: () => open('mailto:$value'),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );

      case 'website':
        return row(
          GestureDetector(
            onTap: () => open(value),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
    }

    return row(Text(value));
  }
}
