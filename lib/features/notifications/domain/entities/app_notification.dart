/// Запись в истории уведомлений пользователя.
class AppNotification {
  /// Рассылка из админки.
  static const kindBroadcast = 'broadcast';

  /// Системное уведомление о подписке.
  static const kindSubscription = 'subscription';

  final String id;

  /// Тип уведомления. Список типов будет расти — неизвестный тип
  /// показывается с иконкой по умолчанию.
  final String kind;
  final String title;
  final String body;
  final String? url;
  final String? imageUrl;
  final int? pushLogId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.url,
    this.imageUrl,
    this.pushLogId,
    this.readAt,
  });

  AppNotification markedRead() {
    if (isRead) return this;
    return AppNotification(
      id: id,
      kind: kind,
      title: title,
      body: body,
      url: url,
      imageUrl: imageUrl,
      pushLogId: pushLogId,
      isRead: true,
      readAt: DateTime.now(),
      createdAt: createdAt,
    );
  }
}

/// Одна страница списка уведомлений.
class AppNotificationsPage {
  final List<AppNotification> items;
  final int currentPage;
  final int lastPage;

  const AppNotificationsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });
}

/// История доступна только авторизованным пользователям: без входа (или с
/// токеном анонимного устройства) API отвечает 401/403.
class NotificationsAuthRequiredException implements Exception {
  const NotificationsAuthRequiredException();

  @override
  String toString() => 'Войдите, чтобы видеть историю уведомлений.';
}
