import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/features/notifications/presentation/providers/notifications_provider.dart';

/// Колокольчик в app bar со счётчиком непрочитанных уведомлений.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // .value держит прошлое число, пока счётчик перечитывается, — бейдж не мигает.
    final count = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    return IconButton(
      tooltip: 'Уведомления',
      onPressed: () => Navigator.pushNamed(context, '/notifications'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_none),
      ),
    );
  }
}
