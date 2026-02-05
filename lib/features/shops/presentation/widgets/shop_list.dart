import 'package:flutter/material.dart';
import '../../domain/entities/shop.dart';
import 'shop_list_item.dart';

class ShopList extends StatelessWidget {
  final List<Shop> shops;
  final ValueChanged<Shop>? onSelect;

  const ShopList({
    super.key,
    required this.shops,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) {
      return const Center(
        child: Text('Магазины не найдены'),
      );
    }

    return ListView.builder(
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];
        return ShopListItem(
          shop: shop,
          onTap: onSelect == null ? null : () => onSelect!(shop),
        );
      },
    );
  }
}