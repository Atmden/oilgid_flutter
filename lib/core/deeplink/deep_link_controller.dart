import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkController {
  DeepLinkController({
    required this.onUri,
    AppLinks? appLinks,
  }) : _appLinks = appLinks ?? AppLinks();

  final void Function(Uri uri) onUri;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  Future<void> start() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        onUri(initialUri);
      }
    } catch (e) {
      debugPrint('DeepLink initial error: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      onUri,
      onError: (Object e) {
        debugPrint('DeepLink stream error: $e');
      },
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}