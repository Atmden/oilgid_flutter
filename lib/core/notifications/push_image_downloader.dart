import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Скачивает картинку пуша во временный файл — и Android (BigPictureStyle),
/// и iOS (DarwinNotificationAttachment) в flutter_local_notifications
/// принимают только локальный путь, не URL.
///
/// Возвращает null при любой ошибке — картинка не критичная часть пуша,
/// уведомление в любом случае должно показаться хотя бы с текстом.
Future<String?> downloadPushImage(String url) async {
  try {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) return null;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/push_image_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (_) {
    return null;
  }
}
