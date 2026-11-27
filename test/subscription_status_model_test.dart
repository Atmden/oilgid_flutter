import 'package:flutter_test/flutter_test.dart';
import 'package:oil_gid/features/subscription/data/models/subscription_status_model.dart';

void main() {
  test('subscriptions_enabled=false с сервера отключает продажи', () {
    final status = SubscriptionStatusModel.fromJson({
      'subscription': null,
      'entitlements': ['garage_book'],
      'subscriptions_enabled': false,
    });

    expect(status.subscriptionsEnabled, isFalse);
    expect(status.isActive, isFalse);
    expect(status.hasEntitlement('garage_book'), isTrue);
  });

  test('без флага (старый бэкенд) подписка считается продаваемой', () {
    final status = SubscriptionStatusModel.fromJson({
      'subscription': null,
      'entitlements': <String>[],
    });

    expect(status.subscriptionsEnabled, isTrue);
    expect(status.hasEntitlement('garage_book'), isFalse);
  });
}
