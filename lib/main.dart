import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/pages/blog.dart';
import 'package:oil_gid/pages/car_history_selected.dart';
import 'package:oil_gid/pages/car_select_screen.dart';
import 'package:oil_gid/pages/car_show_selected.dart';
import 'package:oil_gid/pages/home_page.dart';
import 'package:oil_gid/pages/login.dart';
import 'package:oil_gid/pages/map_screen.dart';
import 'package:oil_gid/pages/oil_details.dart';
import 'package:oil_gid/pages/oil_catalog_page.dart';
import 'package:oil_gid/pages/oil_list.dart';
import 'package:oil_gid/pages/oil_shops_map_page.dart';
import 'package:oil_gid/pages/online_shop_details_page.dart';
import 'package:oil_gid/pages/profile_page.dart';
import 'package:oil_gid/pages/shop_page.dart';
import 'package:oil_gid/pages/shop_products_page.dart';
import 'package:oil_gid/pages/shops_catalog_page.dart';
import 'package:oil_gid/pages/privacy_policy.dart';
import 'package:oil_gid/pages/term_of_use.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oil_gid/features/shops/presentation/shop_route_args.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:upgrader/upgrader.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:async';
import 'package:oil_gid/core/deeplink/deep_link_controller.dart';
import 'package:oil_gid/core/deeplink/deep_link_parser.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:cached_query/cached_query.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CachedQuery.instance.config(
    config: GlobalQueryConfig(
      staleDuration: Duration(minutes: 10),
      cacheDuration: Duration(minutes: 10),
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  await AppApi().initApp();
  await Hive.initFlutter();

  await Hive.openBox('user_cars');

  final accepted = await _checkPrivacyAccepted();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://29cf7334179ac2f3946eecb7b1efc8f1@o4511083723751424.ingest.de.sentry.io/4511083725389904';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: ProviderScope(
          child: MyApp(privacyAccepted: accepted, analytics: analytics),
        ),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool privacyAccepted;
  final FirebaseAnalytics analytics;

  const MyApp({
    super.key,
    required this.privacyAccepted,
    required this.analytics,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final DeepLinkController _deepLinkController;
  late bool _privacyAccepted;
  Uri? _pendingUri;

  @override
  void initState() {
    super.initState();
    _privacyAccepted = widget.privacyAccepted;
    _deepLinkController = DeepLinkController(onUri: _onIncomingUri);
    unawaited(_deepLinkController.start());
  }

  @override
  void dispose() {
    unawaited(_deepLinkController.dispose());
    super.dispose();
  }

  void _onIncomingUri(Uri uri) {
    if (!_privacyAccepted) {
      _pendingUri = uri;
      return;
    }
    _openDeepLink(uri);
  }

  void _openDeepLink(Uri uri) {
    final action = DeepLinkParser.parse(uri);
    if (action is OpenShopDeepLink) {
      _navigatorKey.currentState?.pushNamed(
        '/shop',
        arguments: ShopPageInput.fromId(action.shopId),
      );
    }

    if (action is OpenOilDeepLink) {
      _navigatorKey.currentState?.pushNamed(
        '/oil_details',
        arguments: OilDetailsInput.fromId(action.oilId),
      );
    }
  }

  void _onPrivacyAccepted() {
    final pending = _pendingUri;
    _pendingUri = null;
    setState(() {
      _privacyAccepted = true;
    });
    final nav = _navigatorKey.currentState;
    if (nav == null) return;
    // Убираем TermOfUse из стека
    nav.pushNamedAndRemoveUntil('/home', (route) => false);
    // Если ссылка была отложена — открываем после перехода на home
    if (pending != null) {
      Future.microtask(() => _openDeepLink(pending));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: widget.analytics),
      ],
      builder: (context, child) {
        return UpgradeAlert(
          upgrader: Upgrader(durationUntilAlertAgain: const Duration(days: 1)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 4, 16, 20),
        ),
      ),
      home: _privacyAccepted
          ? const HomePage()
          : TermOfUse(onAccepted: _onPrivacyAccepted),
      routes: {
        '/home': (context) => HomePage(),
        '/privacy_policy': (context) => PrivacyPolicy(),
        '/terms_of_use': (context) => TermOfUse(showAcceptButton: false),
        '/login': (context) => LoginPage(),
        '/car_select': (context) => CarSelectScreen(),
        '/car_show_selected': (context) => CarShowSelected(),
        '/oil_catalog': (context) => const OilCatalogPage(),
        '/oil_list': (context) => OilListPage(),
        '/oil_details': (context) => OilDetailsPage(),
        '/blog': (context) => Blog(),
        '/car_history_selected': (context) => CarHistorySelected(),
        '/map': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as OilShopsMapArgs;
          return MapScreen(shops: args.shops);
        },
        '/oil_shops_map': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as OilShopsMapArgs;
          return OilShopsMapPage(
            shops: args.shops,
            userLat: args.userLat,
            userLng: args.userLng,
          );
        },
        '/shop_products': (context) => const ShopProductsPage(),
        '/shop': (context) => const ShopPage(),
        '/online_shop_details': (context) => const OnlineShopDetailsPage(),
        '/shops_catalog': (context) => const ShopsCatalogPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

Future<bool> _checkPrivacyAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('privacy_accepted') ?? false;
}
