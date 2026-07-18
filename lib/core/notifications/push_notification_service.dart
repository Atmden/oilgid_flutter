import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/core/location/app_location_service.dart';
import 'package:oil_gid/core/notifications/push_channel.dart';
import 'package:oil_gid/core/notifications/push_message_display.dart';

/// Инициализирует push-уведомления (FCM) один раз за время жизни приложения:
/// запрашивает разрешение, регистрирует токен устройства на бэкенде и
/// маршрутизирует тапы по уведомлениям через переданный [onNotificationUrl]
/// (см. вызов из MyApp._onIncomingUri, который уже умеет открывать диплинки).
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  // Топик для широковещательных пушей (акции, обновления каталога и т.д.).
  static const _broadcastTopic = 'all';

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _appApi = AppApi();

  bool _initialized = false;
  Future<void>? _pendingInit;
  void Function(Uri uri)? _onNotificationUrl;

  Future<void> init({required void Function(Uri uri) onNotificationUrl}) {
    _onNotificationUrl = onNotificationUrl;
    if (_initialized) return Future.value();
    return _pendingInit ??= _init().whenComplete(() => _pendingInit = null);
  }

  Future<void> _init() async {
    try {
      await _initLocalNotifications();

      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      final settings = await messaging.requestPermission();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      debugPrint('PUSH: permission status = ${settings.authorizationStatus}');
      if (!granted) return;

      unawaited(messaging.subscribeToTopic(_broadcastTopic));

      final token = await messaging.getToken();
      debugPrint('PUSH: got FCM token = $token');
      await _registerToken(token);
      messaging.onTokenRefresh.listen(_registerToken);

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }
    } catch (_) {
      // Пуши — некритичная функциональность, не блокируем остальной запуск.
    } finally {
      _initialized = true;
    }
  }

  /// Форсирует повторную регистрацию токена сразу после входа/регистрации —
  /// нужно на случай, если разрешение на пуши было выдано ещё анонимно.
  Future<void> registerAfterLogin() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('PUSH: registerAfterLogin token = $token');
      if (token == null) return;
      final position = await AppLocationService.instance.ensureLocation();
      final ok = await _appApi.registerDeviceToken(
        token: token,
        platform: _platformName,
        lat: position?.latitude,
        lng: position?.longitude,
      );
      debugPrint('PUSH: registerAfterLogin ok=$ok');
    } catch (e) {
      debugPrint('PUSH: registerAfterLogin threw: $e');
    }
  }

  /// Отправляет токен и координаты на бэкенд при каждом запуске приложения
  /// (а не только один раз) — так бэкенд всегда видит актуальную геопозицию
  /// устройства, даже если сам FCM-токен не менялся.
  Future<void> _registerToken(String? token) async {
    if (token == null) {
      debugPrint('PUSH: _registerToken called with null token, skipping');
      return;
    }

    final position = await AppLocationService.instance.ensureLocation();
    debugPrint(
      'PUSH: registering token, '
      'position=${position?.latitude},${position?.longitude}',
    );
    try {
      final ok = await _appApi.registerDeviceToken(
        token: token,
        platform: _platformName,
        lat: position?.latitude,
        lng: position?.longitude,
      );
      debugPrint('PUSH: registerDeviceToken ok=$ok');
    } catch (e) {
      debugPrint('PUSH: registerDeviceToken threw: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        final uri = Uri.tryParse(payload);
        if (uri != null) _onNotificationUrl?.call(uri);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(pushAndroidChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    await showPushNotification(_localNotifications, message, alwaysShow: true);
  }

  void _handleMessageTap(RemoteMessage message) {
    final url = message.data['url'];
    if (url is! String) return;
    final uri = Uri.tryParse(url);
    if (uri != null) _onNotificationUrl?.call(uri);
  }

  String get _platformName =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}
