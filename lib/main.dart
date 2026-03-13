import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  await AppApi().initApp();
  await Hive.initFlutter();

  await Hive.openBox('user_cars');

  final accepted = await _checkPrivacyAccepted();

  runApp(
    ProviderScope(
      child: MyApp(privacyAccepted: accepted, analytics: analytics),
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
