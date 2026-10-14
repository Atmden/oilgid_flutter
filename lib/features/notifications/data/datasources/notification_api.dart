import 'package:dio/dio.dart';
import '../../../../core/api/endpoints.dart';
import '../../../../core/utils/parsers.dart';
import '../../domain/entities/app_notification.dart';
import '../models/app_notification_model.dart';

class NotificationApi {
  final Dio _dio;

  NotificationApi(this._dio);

  Future<AppNotificationsPage> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      Endpoints.notifications,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final data = _data(response, 'Не удалось загрузить уведомления.');
    if (data is! Map) throw Exception('Некорректный ответ сервера.');

    final list = data['data'];
    final items = list is List
        ? list
              .whereType<Map<String, dynamic>>()
              .map(AppNotificationModel.fromJson)
              .toList()
        : <AppNotification>[];
    final meta = data['meta'];
    final currentPage = meta is Map ? toIntSafe(meta['current_page']) : null;
    final lastPage = meta is Map ? toIntSafe(meta['last_page']) : null;

    return AppNotificationsPage(
      items: items,
      currentPage: currentPage ?? page,
      lastPage: lastPage ?? currentPage ?? page,
    );
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(Endpoints.notificationsUnreadCount);
    final data = _data(response, 'Не удалось получить число уведомлений.');
    return data is Map ? toIntSafe(data['count']) ?? 0 : 0;
  }

  Future<void> markRead(String id) async {
    final response = await _dio.post(
      Endpoints.notificationRead.replaceAll('{id}', id),
    );
    _data(response, 'Не удалось отметить уведомление прочитанным.');
  }

  /// Отмечает прочитанным уведомление рассылки по номеру [pushLogId] — для
  /// тапа по push, когда id записи в истории ещё неизвестен. Если записи
  /// пока нет, сервер вернёт `updated: 0`, это не ошибка.
  Future<int> markReadByPush(int pushLogId) async {
    final response = await _dio.post(
      Endpoints.notificationsReadByPush.replaceAll(
        '{push_log_id}',
        pushLogId.toString(),
      ),
    );
    final data = _data(response, 'Не удалось отметить уведомление прочитанным.');
    return data is Map ? toIntSafe(data['updated']) ?? 0 : 0;
  }

  Future<int> markAllRead() async {
    final response = await _dio.post(Endpoints.notificationsReadAll);
    final data = _data(response, 'Не удалось отметить уведомления прочитанными.');
    return data is Map ? toIntSafe(data['updated']) ?? 0 : 0;
  }

  Future<void> delete(String id) async {
    final response = await _dio.delete(
      Endpoints.notification.replaceAll('{id}', id),
    );
    _data(response, 'Не удалось удалить уведомление.');
  }

  Future<void> clear() async {
    final response = await _dio.delete(Endpoints.notifications);
    _data(response, 'Не удалось очистить уведомления.');
  }

  /// Проверяет статус и конверт ответа, возвращает его поле `data`.
  dynamic _data(Response response, String fallbackMsg) {
    final status = response.statusCode ?? 0;
    if (status == 401 || status == 403) {
      throw const NotificationsAuthRequiredException();
    }
    final body = response.data;
    if (status >= 400 || (body is Map && body['success'] == false)) {
      throw Exception(_msg(body, fallbackMsg));
    }
    return body is Map ? body['data'] : null;
  }

  String _msg(dynamic body, String fallback) {
    final m = body is Map ? body['message'] : null;
    return (m is String && m.trim().isNotEmpty) ? m.trim() : fallback;
  }
}
