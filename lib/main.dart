import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:oil_gid/features/shops/presentation/shop_route_args.dart';
import 'package:upgrader/upgrader.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:async';
import 'package:oil_gid/core/deeplink/deep_link_controller.dart';
import 'package:oil_gid/core/deeplink/deep_link_parser.dart';
import 'package:oil_gid/features/oils/presentation/oil_route_args.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:cached_query/cached_query.dart';
import 'package:oil_gid/pages/add_car_request_page.dart';
import 'package:oil_gid/core/startup/startup_controller.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  final widgetsBinding = SentryWidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  CachedQuery.instance.config(
    config: GlobalQueryConfig(
      staleDuration: Duration(minutes: 10),
      cacheDuration: Duration(minutes: 10),
    ),
  );

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
    appRunner: () =>
        runApp(SentryWidget(child: ProviderScope(child: AppBootstrap()))),
  );
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<StartupResult> _startupFuture;
  StartupResult? _continuedResult;
  bool _splashRemoved = false;

  @override
  void initState() {
    super.initState();
    _startupFuture = StartupController().initialize();
  }

  void _retryStartup() {
    setState(() {
      _continuedResult = null;
      _startupFuture = StartupController().initialize();
    });
  }

  void _continueWithCurrentResult(StartupResult result) {
    setState(() {
      _continuedResult = result;
    });
  }

  void _removeSplashIfNeeded() {
    if (_splashRemoved) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _splashRemoved) return;
      _splashRemoved = true;
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final continued = _continuedResult;
    if (continued != null) {
      _removeSplashIfNeeded();
      return MyApp(
        privacyAccepted: continued.privacyAccepted,
        analytics: continued.analytics,
      );
    }

    return FutureBuilder<StartupResult>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          _removeSplashIfNeeded();
          return StartupStatusApp(
            title: 'Ошибка инициализации',
            message:
                'Не удалось завершить запуск приложения. Проверьте интернет и попробуйте снова.',
            isLoading: false,
            onRetry: _retryStartup,
            onContinue: () => _continueWithCurrentResult(
              const StartupResult(
                privacyAccepted: false,
                analytics: null,
                issues: [],
              ),
            ),
          );
        }

        final result =
            snapshot.data ??
            const StartupResult(
              privacyAccepted: false,
              analytics: null,
              issues: [],
            );

        if (!result.hasIssues) {
          _removeSplashIfNeeded();
          return MyApp(
            privacyAccepted: result.privacyAccepted,
            analytics: result.analytics,
          );
        }

        _removeSplashIfNeeded();
        final issuesText = result.issues
            .map(
              (issue) =>
                  '- ${issue.step.name}: ${issue.isTimeout ? 'таймаут' : 'ошибка'}',
            )
            .join('\n');

        return StartupStatusApp(
          title: 'Запуск частично завершен',
          message:
              'Некоторые шаги старта не выполнены. Можно повторить инициализацию или продолжить в ограниченном режиме.\n\n$issuesText',
          isLoading: false,
          onRetry: _retryStartup,
          onContinue: () => _continueWithCurrentResult(result),
        );
      },
    );
  }
}

class StartupStatusApp extends StatelessWidget {
  final String title;
  final String message;
  final bool isLoading;
  final VoidCallback? onRetry;
  final VoidCallback? onContinue;

  const StartupStatusApp({
    super.key,
    required this.title,
    required this.message,
    required this.isLoading,
    this.onRetry,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading) const CircularProgressIndicator(),
                  if (isLoading) const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (!isLoading) const SizedBox(height: 24),
                  if (!isLoading)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        if (onRetry != null)
                          ElevatedButton(
                            onPressed: onRetry,
                            child: const Text('Повторить'),
                          ),
                        if (onContinue != null)
                          OutlinedButton(
                            onPressed: onContinue,
                            child: const Text('Продолжить'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final bool privacyAccepted;
  final FirebaseAnalytics? analytics;

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
        if (widget.analytics != null)
          FirebaseAnalyticsObserver(analytics: widget.analytics!),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 4, 16, 20),
        ),
      ),
      home: UpgradeAlert(
        upgrader: Upgrader(
          durationUntilAlertAgain: const Duration(days: 1),
          languageCode: 'ru',
        ),
        child: _privacyAccepted
            ? const HomePage()
            : TermOfUse(onAccepted: _onPrivacyAccepted),
      ),
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
        '/add_car_request': (context) => const AddCarRequestPage(),
      },
    );
  }
}
