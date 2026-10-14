import 'dart:async';

/// Сигнал «история уведомлений могла измениться» — пришёл push, по push
/// тапнули и т.п. Нужен коду вне виджетов (PushNotificationService), чтобы
/// провайдеры истории и бейджа перечитали данные с сервера.
class NotificationInboxEvents {
  NotificationInboxEvents._();

  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  static Stream<void> get changes => _changes.stream;

  static void notifyChanged() => _changes.add(null);
}
