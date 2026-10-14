sealed class DeepLinkAction {
  const DeepLinkAction();
}

class IgnoreDeepLink extends DeepLinkAction {
  const IgnoreDeepLink();
}

class OpenShopDeepLink extends DeepLinkAction {
  final int shopId;

  const OpenShopDeepLink(this.shopId);
}

class OpenOilDeepLink extends DeepLinkAction {
  final int oilId;

  const OpenOilDeepLink(this.oilId);
}

class OpenNotificationsDeepLink extends DeepLinkAction {
  const OpenNotificationsDeepLink();
}

class DeepLinkParser {
  static const _allowedHosts = {'oilgid.kz', 'www.oilgid.kz'};

  /// Ссылка на экран истории уведомлений — её же открывает тап по push без url.
  static final notificationsUri = Uri.parse('https://oilgid.kz/app/notifications');

  static DeepLinkAction parse(Uri uri) {
    if (uri.scheme != 'https') return const IgnoreDeepLink();
    if (!_allowedHosts.contains(uri.host)) return const IgnoreDeepLink();

    // Ожидаем /app/notifications, /app/shop/:shopId, /app/oil/:oilId
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return const IgnoreDeepLink();
    if (segments[0] != 'app') return const IgnoreDeepLink();

    if (segments[1] == 'notifications') {
      return const OpenNotificationsDeepLink();
    }

    if (segments.length < 3) return const IgnoreDeepLink();

    if (segments[1] == 'shop') {
      final shopId = int.tryParse(segments[2]);
      if (shopId == null) return const IgnoreDeepLink();
      return OpenShopDeepLink(shopId);
    }

    if (segments[1] == 'oil') {
      final oilId = int.tryParse(segments[2]);
      if (oilId == null) return const IgnoreDeepLink();
      return OpenOilDeepLink(oilId);
    }

    return const IgnoreDeepLink();
  }
}
