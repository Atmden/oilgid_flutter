class ShopPrice {
  final int volumeId;
  final String label;
  final String value;
  final String unit;
  final double? price;
  final int? quantity;

  const ShopPrice({
    required this.volumeId,
    required this.label,
    required this.value,
    required this.unit,
    this.price,
    this.quantity,
  });
}
