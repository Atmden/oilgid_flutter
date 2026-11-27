import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Флаг страны: PNG с сервера, при ошибке загрузки — emoji.
class CountryFlag extends StatelessWidget {
  final String flagUrl;
  final String flagEmoji;
  final double height;

  const CountryFlag({
    super.key,
    required this.flagUrl,
    required this.flagEmoji,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    final width = height * 1.5;
    final fallback = SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Text(
          flagEmoji,
          style: TextStyle(fontSize: height * 0.9, height: 1),
        ),
      ),
    );

    if (flagUrl.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: CachedNetworkImage(
        imageUrl: flagUrl,
        width: width,
        height: height,
        fit: BoxFit.contain,
        placeholder: (context, url) => SizedBox(width: width, height: height),
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }
}
