import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/core/notifications/notification_inbox_events.dart';
import 'package:oil_gid/core/storage/token_storage.dart';
import 'package:oil_gid/features/notifications/domain/entities/app_notification.dart';

const _perPage = 20;

/// Число непрочитанных уведомлений для бейджа на колокольчике.
///
/// Перечитывается при входе/выходе, возврате приложения из фона и по сигналу
/// [NotificationInboxEvents] (пришёл push, действия на экране истории).
/// Для анонимного пользователя всегда 0 — запрос не отправляется.
final unreadNotificationsCountProvider =
    AsyncNotifierProvider<UnreadNotificationsCountNotifier, int>(
      UnreadNotificationsCountNotifier.new,
      // Бейдж некритичен: при ошибке не долбим сервер повторами, обновимся
      // по следующему событию.
      retry: (_, _) => null,
    );

class UnreadNotificationsCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final subs = [
      NotificationInboxEvents.changes.listen((_) => ref.invalidateSelf()),
      TokenStorage.onUserChanged.stream.listen((_) => ref.invalidateSelf()),
    ];
    final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
    ref.onDispose(() {
      for (final sub in subs) {
        sub.cancel();
      }
      lifecycle.dispose();
    });

    if (!await TokenStorage().isLoggedIn()) return 0;
    try {
      return await AppApi().notificationApi.getUnreadCount();
    } on NotificationsAuthRequiredException {
      return 0;
    }
  }
}

class NotificationsState {
  final List<AppNotification> items;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;

  /// История доступна только после входа — вместо списка показываем
  /// предложение войти.
  final bool requiresLogin;

  const NotificationsState({
    this.items = const [],
    this.currentPage = 0,
    this.lastPage = 0,
    this.isLoadingMore = false,
    this.requiresLogin = false,
  });

  bool get hasMore => currentPage < lastPage;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      requiresLogin: requiresLogin,
    );
  }
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
      retry: (_, _) => null,
    );

class NotificationsNotifier extends AsyncNotifier<NotificationsState> {
  final _api = AppApi().notificationApi;

  @override
  Future<NotificationsState> build() async {
    final subs = [
      TokenStorage.onUserChanged.stream.listen((_) => ref.invalidateSelf()),
      // Пришёл push, пока открыт экран истории, — подтягиваем новые записи.
      NotificationInboxEvents.changes.listen((_) => refresh()),
    ];
    ref.onDispose(() {
      for (final sub in subs) {
        sub.cancel();
      }
    });
    return _loadFirstPage();
  }

  Future<NotificationsState> _loadFirstPage() async {
    if (!await TokenStorage().isLoggedIn()) {
      return const NotificationsState(requiresLogin: true);
    }
    try {
      final page = await _api.getNotifications(perPage: _perPage);
      return NotificationsState(
        items: page.items,
        currentPage: page.currentPage,
        lastPage: page.lastPage,
      );
    } on NotificationsAuthRequiredException {
      return const NotificationsState(requiresLogin: true);
    }
  }

  Future<void> refresh() async {
    // Без AsyncLoading — при pull-to-refresh список не должен пропадать.
    final next = await AsyncValue.guard(_loadFirstPage);
    if (ref.mounted) state = next;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _api.getNotifications(
        page: current.currentPage + 1,
        perPage: _perPage,
      );
      if (!ref.mounted) return;
      // Пока листали, сверху могли появиться новые уведомления и сдвинуть
      // страницы — отбрасываем уже показанные записи.
      final knownIds = current.items.map((n) => n.id).toSet();
      state = AsyncData(
        current.copyWith(
          items: [
            ...current.items,
            ...page.items.where((n) => !knownIds.contains(n.id)),
          ],
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<bool> markRead(String id) async {
    final current = state.value;
    if (current == null) return false;
    final index = current.items.indexWhere((n) => n.id == id);
    if (index == -1 || current.items[index].isRead) return true;

    _setItems(current, [
      for (final n in current.items) n.id == id ? n.markedRead() : n,
    ]);
    try {
      await _api.markRead(id);
      _notifyBadge();
      return true;
    } catch (_) {
      await refresh();
      return false;
    }
  }

  /// Для тапа по уведомлению на экране: отмечает и не ждёт ответа сервера.
  void markReadInBackground(String id) => unawaited(markRead(id));

  Future<bool> markAllRead() async {
    final current = state.value;
    if (current == null) return false;

    _setItems(current, [for (final n in current.items) n.markedRead()]);
    try {
      await _api.markAllRead();
      _notifyBadge();
      return true;
    } catch (_) {
      await refresh();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    final current = state.value;
    if (current == null) return false;

    _setItems(current, current.items.where((n) => n.id != id).toList());
    try {
      await _api.delete(id);
      _notifyBadge();
      return true;
    } catch (_) {
      await refresh();
      return false;
    }
  }

  Future<bool> clear() async {
    final current = state.value;
    if (current == null) return false;

    try {
      await _api.clear();
      if (ref.mounted) {
        state = const AsyncData(NotificationsState());
      }
      _notifyBadge();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _setItems(NotificationsState current, List<AppNotification> items) {
    state = AsyncData(current.copyWith(items: items));
  }

  // Не через NotificationInboxEvents: этот провайдер сам его слушает.
  void _notifyBadge() {
    if (ref.mounted) ref.invalidate(unreadNotificationsCountProvider);
  }
}
