import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// Декодированный (не сжатый) битмап уведомления передаётся системному UI
// через Binder IPC, у которого суммарный лимит транзакции — около 1 МБ.
// Оригиналы с сервера обычно намного больше в памяти после декодирования,
// чем их сжатый файл на диске, поэтому без уменьшения картинка на Android
// молча не показывается (TransactionTooLargeException), хотя текст пуша
// приходит нормально.
const _maxDimension = 512;
const _jpegQuality = 85;

/// Скачивает и уменьшает картинку пуша, сохраняет во временный файл — и
/// Android (BigPictureStyle), и iOS (DarwinNotificationAttachment) в
/// flutter_local_notifications принимают только локальный путь, не URL.
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

    final resized = _resizeForNotification(bytes);
    if (resized == null) return null;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/push_image_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(resized);
    return file.path;
  } catch (_) {
    return null;
  }
}

List<int>? _resizeForNotification(List<int> bytes) {
  final decoded = img.decodeImage(Uint8List.fromList(bytes));
  if (decoded == null) return null;

  final needsResize =
      decoded.width > _maxDimension || decoded.height > _maxDimension;
  final resized = needsResize
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? _maxDimension : null,
          height: decoded.height > decoded.width ? _maxDimension : null,
        )
      : decoded;

  return img.encodeJpg(resized, quality: _jpegQuality);
}
