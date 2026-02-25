import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationLauncher {
  static bool canBuildRoute({
    required double? lat,
    required double? lng,
    required String? address,
  }) {
    return (lat != null && lng != null) || (address?.trim().isNotEmpty ?? false);
  }

  static Future<void> openRoute({
    required BuildContext context,
    required String shopName,
    required double? lat,
    required double? lng,
    required String? address,
  }) async {
    final hasCoords = lat != null && lng != null;
    final hasAddress = address?.trim().isNotEmpty ?? false;

    if (!hasCoords && !hasAddress) {
      _showSnackBar(context, 'Нет данных для построения маршрута');
      return;
    }

    if (hasCoords) {
      final label = Uri.encodeComponent(shopName);
      final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
      if (await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
        return;
      }

      final webCoordsUri = Uri.https(
        'www.google.com',
        '/maps/search/',
        {'api': '1', 'query': '$lat,$lng'},
      );
      if (await launchUrl(
        webCoordsUri,
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    }

    if (hasAddress) {
      final webAddressUri = Uri.https(
        'www.google.com',
        '/maps/search/',
        {'api': '1', 'query': address!.trim()},
      );
      if (await launchUrl(
        webAddressUri,
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    }

    _showSnackBar(context, 'Не удалось открыть навигатор');
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
