import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationLauncher {
  static bool canBuildRoute({
    required double? lat,
    required double? lng,
  }) {
    return lat != null && lng != null;
  }

  static Future<void> openRoute({
    required BuildContext context,
    required String shopName,
    required double? lat,
    required double? lng,
  }) async {
    final hasCoords = lat != null && lng != null;

    if (!hasCoords) {
      _showSnackBar(context, 'Нет данных для построения маршрута');
      return;
    }

    final label = Uri.encodeComponent(shopName);
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    if (await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
      return;
    }

    _showSnackBar(context, 'Не удалось открыть навигатор');
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
