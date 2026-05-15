class SubscriptionPlan {
  final int id;
  final String code;
  final String name;
  final String platform; // "app_store" | "play_market"
  final String productId;
  final String billingPeriod; // "monthly" | "yearly"
  final List<String> entitlements;

  const SubscriptionPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.platform,
    required this.productId,
    required this.billingPeriod,
    required this.entitlements,
  });

  String get periodLabel {
    switch (billingPeriod) {
      case 'monthly':
        return 'в месяц';
      case 'yearly':
        return 'в год';
      case 'weekly':
        return 'в неделю';
      default:
        return '';
    }
  }

  // Платформенный идентификатор для POST /validate-purchase
  String get platformKey => platform;
}
