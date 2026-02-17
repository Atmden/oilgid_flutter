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
import 'package:oil_gid/pages/oil_list.dart';
import 'package:oil_gid/pages/oil_shops_map_page.dart';
import 'package:oil_gid/pages/shop_products_page.dart';
import 'package:oil_gid/pages/privacy_policy.dart';
import 'package:oil_gid/pages/term_of_use.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oil_gid/features/shops/presentation/shop_route_args.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  await AppApi().initApp();
  await Hive.initFlutter();

  await Hive.openBox('user_cars');

  final accepted = await _checkPrivacyAccepted();

  runApp(ProviderScope(child: MyApp(privacyAccepted: accepted, analytics: analytics)));
}

class MyApp extends StatelessWidget {
  final bool privacyAccepted;
  final FirebaseAnalytics analytics;

  const MyApp({super.key, required this.privacyAccepted, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 4, 16, 20),
        ),
      ),
      home: privacyAccepted ? const HomePage() : const TermOfUse(),
      routes: {
        '/home': (context) => HomePage(),
        '/privacy_policy': (context) => PrivacyPolicy(),
        '/terms_of_use': (context) => TermOfUse(showAcceptButton: false),
        '/login': (context) => LoginPage(),
        '/car_select': (context) => CarSelectScreen(),
        '/car_show_selected': (context) => CarShowSelected(),
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
      },
    );
  }
}

Future<bool> _checkPrivacyAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('privacy_accepted') ?? false;
}
