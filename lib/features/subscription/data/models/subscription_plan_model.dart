import '../../../../core/utils/parsers.dart';
import '../../domain/entities/subscription_plan.dart';

class SubscriptionPlanModel extends SubscriptionPlan {
  const SubscriptionPlanModel({
    required super.id,
    required super.code,
    required super.name,
    required super.platform,
    required super.productId,
    required super.billingPeriod,
    required super.entitlements,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final rawEntitlements = json['entitlements'];
    return SubscriptionPlanModel(
      id: toIntSafe(json['id']) ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      billingPeriod: json['billing_period']?.toString() ?? 'monthly',
      entitlements: rawEntitlements is List
          ? rawEntitlements.whereType<String>().toList()
          : [],
    );
  }
}
