import 'package:flutter/material.dart';
import '../../domain/entities/shop.dart';

class ShopListItem extends StatelessWidget {
  final Shop shop;
  final VoidCallback? onTap;

  const ShopListItem({
    super.key,
    required this.shop,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distanceKm = (shop.distanceM != null)
        ? (shop.distanceM! / 1000).toStringAsFixed(1)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(
          shop.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shop.address.isNotEmpty) Text(shop.address),
            if (shop.phone != null && shop.phone!.isNotEmpty)
              Text('Тел: ${shop.phone}'),
            if (distanceKm != null) Text('~$distanceKm км'),
          ],
        ),
        trailing: shop.price != null
            ? Text('${shop.price!.toStringAsFixed(0)} ₸')
            : null,
        isThreeLine: true,
      ),
    );
  }
}