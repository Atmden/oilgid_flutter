import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/features/shops/domain/entities/shop.dart';
import 'package:oil_gid/features/shops/presentation/shop_route_args.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_approval.dart';
import 'package:oil_gid/features/oils/domain/entities/oil_item.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:oil_gid/themes/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oil_gid/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:oil_gid/features/shops/presentation/widgets/shop_list.dart';
import 'package:oil_gid/features/oils/presentation/widgets/oil_gallery.dart';
import 'package:oil_gid/features/oils/presentation/widgets/oil_approvals_group.dart';

class OilDetailsPage extends StatefulWidget {
  const OilDetailsPage({super.key});

  @override
  State<OilDetailsPage> createState() => _OilDetailsPageState();
}

class _OilDetailsPageState extends State<OilDetailsPage> {
  bool _initialized = false;
  OilItem? _item;
  int _currentIndex = 0;
  String _volume = '';
  String _description = '';
  Position? _userLocation;
  Future<List<Shop>>? _shopsFuture;
  final _shopRepository = ShopRepositoryImpl(AppApi().shopModelApi);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OilDetailsArgs) {
      _item = args.item;
      _volume = args.volume;
      _description = args.description;
    }

    _loadUserLocation().then((value) {
      if (!mounted) return;
      if (_item == null) return;
      setState(() {
        _userLocation = value;
        _shopsFuture = _shopRepository.getShopsMarkers(
          oilId: _item!.id,
          lat: value?.latitude,
          lng: value?.longitude,
          radiusKm: 150,
        );
      });
    });
  }

  Future<Position?> _loadUserLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Масло'),
        ),
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Нет данных для отображения')),
      );
    }

    final images = item.resolveImages();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(item.title),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OilGallery(
              images: images,
              onTap: (index) => _openGallery(images, index),
            ),
            const SizedBox(height: 16),
            InfoBlock(
              title: 'Характеристики',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(label: 'Бренд', value: item.brandTitle),
                  InfoRow(label: 'Вязкость', value: item.viscosityTitle),
                  if (_volume.isNotEmpty)
                    InfoRow(label: 'Требуемый объем', value: '$_volume л.'),
                  if (_description.isNotEmpty)
                    InfoRow(label: 'Описание', value: _description),
                  if (item.specification != null)
                    ApprovalsGroup(
                      title: 'ACEA',
                      values: item.specification!.aceas,
                    ),
                  if (item.specification != null)
                    ApprovalsGroup(
                      title: 'API',
                      values: item.specification!.apis,
                    ),
                  if (item.specification != null)
                    ApprovalsGroup(
                      title: 'OEM',
                      values: item.specification!.oemApprovals,
                    ),
                  if (item.specification != null)
                    ApprovalsGroup(
                      title: 'ILSAC',
                      values: item.specification!.ilsacs,
                    ),
                ],
              ),
            ),

            if (_shopsFuture != null) ...[
              const SizedBox(height: 16),

              InfoBlock(
                title: 'Ближайшие магазины',
                child: Column(
                  children: [
                    FutureBuilder<List<Shop>>(
                      future: _shopsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text('Не удалось загрузить магазины');
                        }
                        final shops = snapshot.data ?? [];
                        return SizedBox(
                          height: 300,
                          child: Scrollbar(child: ShopList(shops: shops)),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        _shopsFuture!.then((shops) {
                          Navigator.pushNamed(
                            context,
                            '/map',
                            arguments: OilShopsMapArgs(shops: shops),
                          );
                        });
                      },
                      child: const Text('Показать магазины на карте'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (item.brand != null &&
                (item.brand!.logo.isNotEmpty ||
                    item.brand!.description.isNotEmpty))
              InfoBlock(
                title: 'О бренде',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.brand!.logo.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: item.brand!.logo,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      const SizedBox(width: 24, height: 24),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.business),
                                ),
                              ),
                            ),
                          ),
                        if (item.brand!.logo.isNotEmpty)
                          const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.brandTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                    if (item.brand!.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          item.brand!.description,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                  ],
                ),
              ),
            if (item.description.isNotEmpty) const SizedBox(height: 12),
            if (item.description.isNotEmpty)
              InfoBlock(
                title: 'Описание',
                child: Text(item.description, textAlign: TextAlign.justify),
              ),
          ],
        ),
      ),
    );
  }

  void _openGallery(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _OilGalleryViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }
}

class _OilGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _OilGalleryViewer({required this.images, required this.initialIndex});

  @override
  State<_OilGalleryViewer> createState() => _OilGalleryViewerState();
}

class _OilGalleryViewerState extends State<_OilGalleryViewer> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        itemCount: widget.images.length,
        controller: PageController(initialPage: widget.initialIndex),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Container(
              color: Colors.white,
              alignment: Alignment.center,
              width: double.infinity,
              height: double.infinity,
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
