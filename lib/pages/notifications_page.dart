import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/deeplink/deep_link_navigator.dart';
import 'package:oil_gid/features/notifications/domain/entities/app_notification.dart';
import 'package:oil_gid/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/themes/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final data = state.value;
    final showMenu =
        data != null && !data.requiresLogin && data.items.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MainAppBar(
        title: 'Уведомления',
        actions: [if (showMenu) _MenuButton(items: data.items)],
      ),
      body: SafeArea(
        child: state.when(
          // При refresh() провайдер отдаёт прошлые данные, так что спиннер
          // виден только при первой загрузке.
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: e.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
          data: (data) {
            if (data.requiresLogin) return const _LoginPrompt();
            return _NotificationsList(state: data);
          },
        ),
      ),
    );
  }
}

class _MenuButton extends ConsumerWidget {
  const _MenuButton({required this.items});

  final List<AppNotification> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = items.any((n) => !n.isRead);
    return PopupMenuButton<String>(
      onSelected: (value) async {
        final notifier = ref.read(notificationsProvider.notifier);
        final messenger = ScaffoldMessenger.of(context);
        if (value == 'read_all') {
          final ok = await notifier.markAllRead();
          if (!ok) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Не удалось отметить прочитанными')),
            );
          }
        } else if (value == 'clear') {
          final confirmed = await _confirmClear(context);
          if (confirmed != true) return;
          final ok = await notifier.clear();
          if (!ok) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Не удалось очистить уведомления')),
            );
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'read_all',
          enabled: hasUnread,
          child: const Text('Прочитать все'),
        ),
        const PopupMenuItem(value: 'clear', child: Text('Очистить')),
      ],
    );
  }

  Future<bool?> _confirmClear(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить уведомления?'),
        content: const Text('Все уведомления будут удалены без возможности восстановления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}

class _NotificationsList extends ConsumerStatefulWidget {
  const _NotificationsList({required this.state});

  final NotificationsState state;

  @override
  ConsumerState<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends ConsumerState<_NotificationsList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() => ref.read(notificationsProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final items = widget.state.items;

    if (items.isEmpty) {
      // ListView, чтобы pull-to-refresh работал и на пустом экране.
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [SizedBox(height: 120), _EmptyView()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length + (widget.state.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final notification = items[index];
          return _DismissibleTile(
            key: ValueKey(notification.id),
            notification: notification,
          );
        },
      ),
    );
  }
}

class _DismissibleTile extends ConsumerWidget {
  const _DismissibleTile({super.key, required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('dismiss_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await ref
            .read(notificationsProvider.notifier)
            .delete(notification.id);
        if (!ok) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Не удалось удалить уведомление')),
          );
        }
      },
      child: _NotificationTile(
        notification: notification,
        onTap: () => _open(context, ref),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    ref
        .read(notificationsProvider.notifier)
        .markReadInBackground(notification.id);

    final uri = notification.url == null ? null : Uri.tryParse(notification.url!);
    if (uri == null) {
      _showDetails(context, notification);
      return;
    }
    if (!openDeepLink(Navigator.of(context), uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDetails(BuildContext context, AppNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notification.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: notification.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatNotificationDate(notification.createdAt),
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(notification.body, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: unread ? Colors.white : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: unread ? AppColors.accentDark : AppColors.border,
                width: unread ? 1.2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KindIcon(kind: notification.kind, unread: unread),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: unread
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: AppColors.accentDark,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (notification.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                      if (notification.imageUrl != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: notification.imageUrl!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        formatNotificationDate(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind, required this.unread});

  final String kind;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      AppNotification.kindBroadcast => Icons.campaign_outlined,
      AppNotification.kindSubscription => Icons.workspace_premium_outlined,
      _ => Icons.notifications_none,
    };
    return CircleAvatar(
      radius: 20,
      backgroundColor: unread ? AppColors.primarySoft : AppColors.border,
      child: Icon(
        icon,
        size: 22,
        color: unread ? Colors.white : AppColors.primarySoft,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.black26),
          SizedBox(height: 16),
          Text(
            'Здесь появятся уведомления о скидках и вашей подписке',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 72,
              color: Colors.black26,
            ),
            const SizedBox(height: 24),
            const Text(
              'История уведомлений',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Войдите, чтобы видеть все уведомления о скидках и вашей подписке в одном месте.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            // После входа провайдер перечитает историю сам
            // (TokenStorage.onUserChanged).
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/login',
                arguments: {'returnToCaller': true},
              ),
              child: const Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

/// «13:05» — сегодня, «Вчера, 13:05», иначе «14.10.2026, 13:05».
String formatNotificationDate(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  final time = '${two(date.hour)}:${two(date.minute)}';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return time;
  if (diff == 1) return 'Вчера, $time';
  return '${two(date.day)}.${two(date.month)}.${date.year}, $time';
}
