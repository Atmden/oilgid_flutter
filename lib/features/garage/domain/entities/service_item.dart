class ServiceItem {
  final int? id;
  final String name;
  final int quantity;
  final double unitPrice;

  const ServiceItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });
}
