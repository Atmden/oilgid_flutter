import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oil_gid/themes/app_colors.dart';

class OilGallery extends StatefulWidget {
  final List<String> images;
  final void Function(int index)? onTap;

  const OilGallery({
    super.key,
    required this.images,
    this.onTap,
  });

  @override
  State<OilGallery> createState() => _OilGalleryState();
}

class _OilGalleryState extends State<OilGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    if (images.isEmpty) {
      return _emptyGallery();
    }

    return Column(
      children: [
        _buildPageView(images),
        if (images.length > 1) const SizedBox(height: 8),
        if (images.length > 1) _buildDots(images.length),
      ],
    );
  }

  Widget _buildPageView(List<String> images) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: images.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => widget.onTap?.call(index),
            child: Container(
              padding: const EdgeInsets.all(12),
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

  Widget _emptyGallery() {
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
}

