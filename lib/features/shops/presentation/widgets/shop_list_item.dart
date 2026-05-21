import 'package:flutter/material.dart';
import 'package:oil_gid/themes/app_colors.dart';
import '../../domain/entities/shop.dart';

String _formatPrice(double price) {
  final intPart = price.truncate();
  final s = intPart.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

class ShopListItem extends StatelessWidget {
  final Shop shop;
  final VoidCallback? onTap;

  const ShopListItem({super.key, required this.shop, this.onTap});

  @override
  Widget build(BuildContext context) {
    final distanceKm = (shop.distanceM != null)
        ? (shop.distanceM! / 1000).toStringAsFixed(1)
        : null;
    final hasOnlinePurchase = shop.onlinePurchaseAvailable;
    final accentColor = AppColors.accentLight;
    final cardColor = hasOnlinePurchase
        ? accentColor.withAlpha(90)
        : Colors.white;

    Widget? trailingWidget;
    if (shop.prices.isNotEmpty) {
      final minPrice = shop.prices
          .map((p) => p.price)
          .whereType<double>()
          .fold<double?>(null, (a, b) => a == null || b < a ? b : a);
      if (minPrice != null) {
        trailingWidget = Text(
          'от ${_formatPrice(minPrice)} ₸',
          style: const TextStyle(fontWeight: FontWeight.w600),
        );
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasOnlinePurchase ? accentColor : AppColors.border,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          shop.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shop.city.isNotEmpty) Text(shop.city),
            if (shop.address.isNotEmpty) Text(shop.address),
            if (shop.phone != null && shop.phone!.isNotEmpty)
              Text('Тел: ${shop.phone}'),
            if (shop.workingHours != null &&
                shop.workingHours!.trim().isNotEmpty)
              Text('Режим работы: ${shop.workingHours}'),
            if (distanceKm != null) Text('~$distanceKm км'),
            if (hasOnlinePurchase)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: AppColors.accentDark),
                    Text(
                      'Можно купить онлайн',
                      style: TextStyle(
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: trailingWidget,
        isThreeLine: true,
      ),
    );
  }
}
