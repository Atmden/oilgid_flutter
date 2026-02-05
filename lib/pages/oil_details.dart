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

    final images = _resolveImages(item);
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
            _buildGallery(images),
            if (images.length > 1) const SizedBox(height: 8),
            if (images.length > 1) _buildDots(images.length),
            const SizedBox(height: 16),
            _InfoBlock(
              title: 'Характеристики',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Бренд', value: item.brandTitle),
                  _InfoRow(label: 'Вязкость', value: item.viscosityTitle),
                  if (_volume.isNotEmpty)
                    _InfoRow(label: 'Требуемый объем', value: '$_volume л.'),
                  if (_description.isNotEmpty)
                    _InfoRow(label: 'Описание', value: _description),
                  if (item.specification != null)
                    _ApprovalsGroup(
                      title: 'ACEA',
                      values: item.specification!.aceas,
                    ),
                  if (item.specification != null)
                    _ApprovalsGroup(
                      title: 'API',
                      values: item.specification!.apis,
                    ),
                  if (item.specification != null)
                    _ApprovalsGroup(
                      title: 'OEM',
                      values: item.specification!.oemApprovals,
                    ),
                  if (item.specification != null)
                    _ApprovalsGroup(
                      title: 'ILSAC',
                      values: item.specification!.ilsacs,
                    ),
                ],
              ),
            ),

            if (_shopsFuture != null) ...[
              const SizedBox(height: 16),

              _InfoBlock(
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
                            arguments: OilShopsMapArgs(
                              shops: shops,
                            ),
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
              _InfoBlock(
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
              _InfoBlock(
                title: 'Описание',
                child: Text(item.description, textAlign: TextAlign.justify),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _resolveImages(OilItem item) {
    if (item.images.isNotEmpty) {
      return item.images;
    }
    if (item.thumb.isNotEmpty) {
      return [item.thumb];
    }
    return [];
  }

  Widget _buildGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Icon(Icons.oil_barrel, size: 48, color: Colors.black54),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openGallery(images, index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.oil_barrel,
                    size: 40,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.black26,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
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

class _InfoBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ApprovalsGroup extends StatelessWidget {
  final String title;
  final List<OilApproval> values;

  const _ApprovalsGroup({required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values
                .where((item) => item.title.isNotEmpty)
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      item.title,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
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
            child: Center(
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
