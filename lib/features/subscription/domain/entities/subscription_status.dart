class SubscriptionStatus {
  final bool isActive;
  final DateTime? expiresAt;
  final List<String> entitlements;

  /// Продаётся ли подписка сейчас (флаг с сервера). Если false — блок
  /// подписки и кнопки покупки не показываем.
  final bool subscriptionsEnabled;

  const SubscriptionStatus({
    required this.isActive,
    this.expiresAt,
    required this.entitlements,
    this.subscriptionsEnabled = true,
  });

  bool hasEntitlement(String key) => entitlements.contains(key);
}
