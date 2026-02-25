import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/features/shops/domain/entities/shop_details.dart';
import 'package:oil_gid/themes/app_colors.dart';

class ShopGallery extends StatefulWidget {
  final List<ShopGalleryImage> gallery;

  const ShopGallery({super.key, required this.gallery});

  @override
  State<ShopGallery> createState() => _ShopGalleryState();
}

class _ShopGalleryState extends State<ShopGallery> {
  int _currentIndex = 0;
  late final PageController _pageController;
  static const int _visibleThumbs = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.34);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gallery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 96,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: widget.gallery.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = _resolveActiveDotIndex(index));
            },
            itemBuilder: (context, index) {
              final item = widget.gallery[index];
              return GestureDetector(
                onTap: () => _openViewer(index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.thumb,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.gallery.length > 1) const SizedBox(height: 8),
        if (widget.gallery.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.gallery.length, (index) {
              final active = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
      ],
    );
  }

  void _openViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ShopGalleryViewer(
          gallery: widget.gallery,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  int _resolveActiveDotIndex(int firstVisibleIndex) {
    final lastVisibleIndex = firstVisibleIndex + _visibleThumbs - 1;
    return lastVisibleIndex.clamp(0, widget.gallery.length - 1);
  }
}

class _ShopGalleryViewer extends StatefulWidget {
  final List<ShopGalleryImage> gallery;
  final int initialIndex;

  const _ShopGalleryViewer({
    required this.gallery,
    required this.initialIndex,
  });

  @override
  State<_ShopGalleryViewer> createState() => _ShopGalleryViewerState();
}

class _ShopGalleryViewerState extends State<_ShopGalleryViewer> {
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
        title: Text('${_currentIndex + 1} / ${widget.gallery.length}'),
      ),
      body: PageView.builder(
        itemCount: widget.gallery.length,
        controller: PageController(initialPage: widget.initialIndex),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final image = widget.gallery[index];
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              width: double.infinity,
              height: double.infinity,
              child: CachedNetworkImage(
                imageUrl: image.photo.isNotEmpty ? image.photo : image.thumb,
                fit: BoxFit.contain,
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
