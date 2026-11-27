import '../../domain/entities/subscription_status.dart';

class SubscriptionStatusModel extends SubscriptionStatus {
  const SubscriptionStatusModel({
    required super.isActive,
    super.expiresAt,
    required super.entitlements,
    super.subscriptionsEnabled,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    // Структура: { subscription: { status, expires_at, ... }, entitlements: [...] }
    final subJson = json['subscription'];
    final rawEntitlements = json['entitlements'];
    // Старый бэкенд флаг не отдаёт — считаем, что подписка продаётся.
    final rawEnabled = json['subscriptions_enabled'];

    bool isActive = false;
    DateTime? expiresAt;

    if (subJson is Map<String, dynamic>) {
      isActive = subJson['status'] == 'active';
      final raw = subJson['expires_at'];
      if (raw is String) expiresAt = DateTime.tryParse(raw);
    }

    return SubscriptionStatusModel(
      isActive: isActive,
      expiresAt: expiresAt,
      entitlements: rawEntitlements is List
          ? rawEntitlements.whereType<String>().toList()
          : [],
      subscriptionsEnabled: rawEnabled is bool ? rawEnabled : true,
    );
  }
}
