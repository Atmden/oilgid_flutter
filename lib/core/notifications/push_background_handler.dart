import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:oil_gid/core/notifications/push_channel.dart';
import 'package:oil_gid/core/notifications/push_message_display.dart';
import 'package:oil_gid/firebase_options.dart';

/// Выполняется в отдельном background-изоляте — не имеет доступа к состоянию
/// PushNotificationService из основного изолята, поэтому инициализирует
/// Firebase и плагин локальных уведомлений заново.
@pragma('vm:entry-point')
Future<void> pushBackgroundMessageHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Сообщения с полем `notification` система уже показала сама — здесь нужно
  // дорисовать только "data-only" пуши (см. showPushNotification).
  if (message.notification != null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(pushAndroidChannel);

  await showPushNotification(plugin, message, alwaysShow: true);
}
