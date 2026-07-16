import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Общий Android-канал уведомлений — используется и из foreground-обработчика
/// (PushNotificationService), и из background-изолята (pushBackgroundMessageHandler),
/// поэтому вынесен в отдельный файл, чтобы id/name не разъехались между ними.
const pushAndroidChannel = AndroidNotificationChannel(
  'default_notifications',
  'Уведомления',
  description: 'Основной канал push-уведомлений OilGid',
  importance: Importance.high,
);
