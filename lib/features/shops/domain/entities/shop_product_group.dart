/// Способ группировки товаров в каталоге магазина.
enum ShopProductGrouping {
  brand('brand'),
  viscosity('viscosity');

  final String apiValue;

  const ShopProductGrouping(this.apiValue);
}

/// Группа товаров магазина (бренд или вязкость) для аккордеона.
class ShopProductGroup {
  final ShopProductGrouping type;

  /// null — группа «Без вязкости».
  final int? id;
  final String title;
  final String logo;
  final int productsCount;

  const ShopProductGroup({
    required this.type,
    required this.id,
    required this.title,
    required this.logo,
    required this.productsCount,
  });

  /// Значение фильтра viscosity_id для запроса товаров группы.
  String get viscosityFilter => id?.toString() ?? 'none';
}
