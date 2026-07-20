import 'package:flutter/material.dart';
import 'package:oil_gid/core/notifications/push_notification_service.dart';
import 'package:oil_gid/pages/onboarding/permission_intro_scaffold.dart';

class NotificationPermissionPage extends StatefulWidget {
  const NotificationPermissionPage({
    super.key,
    required this.onNotificationUrl,
    required this.onDone,
  });

  final void Function(Uri uri) onNotificationUrl;
  final VoidCallback onDone;

  @override
  State<NotificationPermissionPage> createState() =>
      _NotificationPermissionPageState();
}

class _NotificationPermissionPageState
    extends State<NotificationPermissionPage> {
  bool _requesting = false;

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    await PushNotificationService.instance.init(
      onNotificationUrl: widget.onNotificationUrl,
    );
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionIntroScaffold(
      icon: Icons.notifications_active_outlined,
      title: 'Не пропустите акции и новости',
      description:
          'Разрешите уведомления, чтобы узнавать об акциях в магазинах, '
          'новых поступлениях масел и статусе ваших заказов.',
      isLoading: _requesting,
      onAllow: _requestPermission,
      onSkip: widget.onDone,
    );
  }
}
