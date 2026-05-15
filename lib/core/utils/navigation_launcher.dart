import 'dart:io';

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
    if (lat == null || lng == null) {
      _showSnackBar(context, 'Нет данных для построения маршрута');
      return;
    }

    if (Platform.isIOS) {
      await _openRouteIOS(context, shopName, lat, lng);
    } else {
      final label = Uri.encodeComponent(shopName);
      final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
      if (!await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        _showSnackBar(context, 'Не удалось открыть навигатор');
      }
    }
  }

  static Future<void> _openRouteIOS(
    BuildContext context,
    String shopName,
    double lat,
    double lng,
  ) async {
    final label = Uri.encodeComponent(shopName);

    final candidates = <_NavApp>[];

    if (await canLaunchUrl(Uri.parse('yandexmaps://'))) {
      candidates.add(_NavApp(
        name: 'Яндекс Карты',
        icon: Icons.map_outlined,
        uri: Uri.parse('yandexmaps://maps.yandex.ru/?pt=$lng,$lat&z=15&l=map'),
      ));
    }

    if (await canLaunchUrl(Uri.parse('dgis://'))) {
      candidates.add(_NavApp(
        name: '2GIS',
        icon: Icons.map_outlined,
        uri: Uri.parse('dgis://2gis.ru/routeSearch/rsType/car/to/$lng,$lat'),
      ));
    }

    if (await canLaunchUrl(Uri.parse('comgooglemaps://'))) {
      candidates.add(_NavApp(
        name: 'Google Maps',
        icon: Icons.map_outlined,
        uri: Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving'),
      ));
    }

    // Apple Maps всегда доступен
    candidates.add(_NavApp(
      name: 'Apple Maps',
      icon: Icons.map_outlined,
      uri: Uri.parse('https://maps.apple.com/?ll=$lat,$lng&q=$label'),
    ));

    if (candidates.length == 1) {
      await launchUrl(candidates.first.uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;

    final chosen = await showModalBottomSheet<_NavApp>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'Открыть в навигаторе',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...candidates.map(
              (app) => ListTile(
                leading: Icon(app.icon),
                title: Text(app.name),
                onTap: () => Navigator.of(ctx).pop(app),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (chosen == null) return;
    await launchUrl(chosen.uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> openWhatsAppPurchase({
    required BuildContext context,
    required String phone,
    required String message,
  }) async {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      _showSnackBar(context, 'Номер WhatsApp не указан');
      return;
    }

    final encodedText = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('https://wa.me/$digitsOnly?text=$encodedText');
    final opened = await launchUrl(
      whatsappUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Не удалось открыть WhatsApp');
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NavApp {
  final String name;
  final IconData icon;
  final Uri uri;

  const _NavApp({required this.name, required this.icon, required this.uri});
}
