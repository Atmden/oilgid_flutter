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

    if (!context.mounted) return;
    _showSnackBar(context, 'Не удалось открыть навигатор');
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
