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
        try {
          onUri(initialUri);
        } catch (e) {
          debugPrint('DeepLink initial handler error: $e');
        }
      }
    } catch (e) {
      debugPrint('DeepLink initial error: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) {
        try {
          onUri(uri);
        } catch (e) {
          debugPrint('DeepLink stream handler error: $e');
        }
      },
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