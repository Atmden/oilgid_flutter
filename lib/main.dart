import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/pages/blog.dart';
import 'package:oil_gid/pages/car_history_selected.dart';
import 'package:oil_gid/pages/car_select_screen.dart';
import 'package:oil_gid/pages/car_show_selected.dart';
import 'package:oil_gid/pages/home_page.dart';
import 'package:oil_gid/pages/login.dart';
import 'package:oil_gid/pages/privacy_policy.dart';
import 'package:oil_gid/pages/term_of_use.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppApi().initApp();
  await Hive.initFlutter();

  await Hive.openBox('user_cars');

  final accepted = await _checkPrivacyAccepted();

  runApp(ProviderScope(child: MyApp(privacyAccepted: accepted)));
}

class MyApp extends StatelessWidget {
  final bool privacyAccepted;

  const MyApp({super.key, required this.privacyAccepted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/blog': (context) => Blog(),
        '/car_history_selected': (context) => CarHistorySelected(),
      },
    );
  }
}

Future<bool> _checkPrivacyAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('privacy_accepted') ?? false;
}
