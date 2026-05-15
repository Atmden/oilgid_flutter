class SubscriptionStatus {
  final bool isActive;
  final DateTime? expiresAt;
  final List<String> entitlements;

  const SubscriptionStatus({
    required this.isActive,
    this.expiresAt,
    required this.entitlements,
  });

  bool hasEntitlement(String key) => entitlements.contains(key);
}
