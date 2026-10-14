import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oil_gid/core/deeplink/deep_link_parser.dart';
import 'package:oil_gid/core/notifications/push_message_display.dart';
import 'package:oil_gid/features/notifications/data/models/app_notification_model.dart';

void main() {
  group('AppNotificationModel.fromJson', () {
    test('разбирает пример из спецификации', () {
      final n = AppNotificationModel.fromJson({
        'id': 'd6105393-2dee-4450-803e-6c0a1e9abfee',
        'kind': 'broadcast',
        'title': 'Скидка 15% на Shell Helix',
        'body': 'До конца недели',
        'url': 'https://oilgid.kz/app/oil/45',
        'image_url': 'https://oilgid.kz/storage/push-notifications/01J9X.jpg',
        'push_log_id': 34,
        'is_read': false,
        'read_at': null,
        'created_at': '2026-10-14T13:05:44+05:00',
      });

      expect(n.id, 'd6105393-2dee-4450-803e-6c0a1e9abfee');
      expect(n.pushLogId, 34);
      expect(n.isRead, isFalse);
      expect(n.readAt, isNull);
      expect(
        n.createdAt.toUtc(),
        DateTime.utc(2026, 10, 14, 8, 5, 44),
      );
      expect(n.markedRead().isRead, isTrue);
    });

    test('пустые url и image_url считаются отсутствующими', () {
      final n = AppNotificationModel.fromJson({
        'id': '1',
        'kind': 'subscription',
        'url': '',
        'image_url': null,
        'created_at': '2026-10-14T13:05:44+05:00',
      });
      expect(n.url, isNull);
      expect(n.imageUrl, isNull);
      expect(n.pushLogId, isNull);
    });
  });

  group('decodePushPayload', () {
    test('JSON с data-полями', () {
      final data = decodePushPayload(
        jsonEncode({'kind': 'broadcast', 'push_log_id': '34'}),
      );
      expect(data['push_log_id'], '34');
    });

    test('старый payload — просто url', () {
      final data = decodePushPayload('https://oilgid.kz/app/shop/1');
      expect(data, {'url': 'https://oilgid.kz/app/shop/1'});
    });
  });

  group('DeepLinkParser', () {
    test('экран уведомлений', () {
      expect(
        DeepLinkParser.parse(DeepLinkParser.notificationsUri),
        isA<OpenNotificationsDeepLink>(),
      );
    });

    test('магазин и масло по-прежнему разбираются', () {
      final shop = DeepLinkParser.parse(
        Uri.parse('https://oilgid.kz/app/shop/123'),
      );
      expect(shop, isA<OpenShopDeepLink>());
      expect((shop as OpenShopDeepLink).shopId, 123);
      expect(
        DeepLinkParser.parse(Uri.parse('https://www.oilgid.kz/app/oil/45/')),
        isA<OpenOilDeepLink>(),
      );
    });

    test('чужие и неполные ссылки игнорируются', () {
      for (final url in [
        'https://example.com/app/notifications',
        'http://oilgid.kz/app/notifications',
        'https://oilgid.kz/app',
        'https://oilgid.kz/app/shop',
        'https://oilgid.kz/app/shop/abc',
      ]) {
        expect(
          DeepLinkParser.parse(Uri.parse(url)),
          isA<IgnoreDeepLink>(),
          reason: url,
        );
      }
    });
  });
}
