import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:oil_gid/core/notifications/push_channel.dart';
import 'package:oil_gid/core/notifications/push_image_downloader.dart';

/// Показывает локальное уведомление для [message].
///
/// FCM-сообщения бывают двух видов:
/// - с полем `notification` — на background/terminated система показывает их
///   сама, показывать их ещё раз (не с [alwaysShow]) значит получить дубль;
/// - "data-only" (только `data`, без `notification`) — их FCM никогда не
///   показывает сам, ни в foreground, ни в background, поэтому показываем
///   всегда, используя title/body из data.
///
/// [alwaysShow] нужен для foreground-случая: там система в принципе не
/// показывает системный баннер сама (см. setForegroundNotificationPresentationOptions),
/// поэтому уведомления с `notification`-полем в foreground тоже показываем сами.
Future<void> showPushNotification(
  FlutterLocalNotificationsPlugin plugin,
  RemoteMessage message, {
  required bool alwaysShow,
}) async {
  final notification = message.notification;
  if (notification != null && !alwaysShow) {
    // Система уже показала это уведомление сама (background/terminated).
    return;
  }

  final title = notification?.title ?? message.data['title'] as String?;
  final body = notification?.body ?? message.data['body'] as String?;
  if (title == null && body == null) return;

  final imageUrl =
      notification?.android?.imageUrl ??
      notification?.apple?.imageUrl ??
      message.data['image'] as String?;
  final imagePath = imageUrl == null ? null : await downloadPushImage(imageUrl);

  await plugin.show(
    id: message.hashCode & 0x7fffffff,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        pushAndroidChannel.id,
        pushAndroidChannel.name,
        channelDescription: pushAndroidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: imagePath == null
            ? null
            : BigPictureStyleInformation(
                FilePathAndroidBitmap(imagePath),
                largeIcon: FilePathAndroidBitmap(imagePath),
                hideExpandedLargeIcon: true,
              ),
      ),
      iOS: DarwinNotificationDetails(
        attachments: imagePath == null
            ? null
            : [DarwinNotificationAttachment(imagePath)],
      ),
    ),
    payload: message.data['url'] as String?,
  );
}
