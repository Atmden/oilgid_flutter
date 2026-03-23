import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/firebase_options.dart';

enum StartupStep { firebase, appInit, hiveInit, hiveOpenBox, prefs }

class StartupIssue {
  final StartupStep step;
  final bool isTimeout;
  final Object error;
  final StackTrace? stackTrace;

  const StartupIssue({
    required this.step,
    required this.isTimeout,
    required this.error,
    required this.stackTrace,
  });
}

class StartupResult {
  final bool privacyAccepted;
  final FirebaseAnalytics? analytics;
  final List<StartupIssue> issues;

  const StartupResult({
    required this.privacyAccepted,
    required this.analytics,
    required this.issues,
  });

  bool get hasIssues => issues.isNotEmpty;
}

class StartupTimeoutException implements Exception {
  final StartupStep step;
  final Duration timeout;

  const StartupTimeoutException(this.step, this.timeout);

  @override
  String toString() => 'Startup step $step timed out after $timeout';
}

class StartupController {
  StartupController({
    AppApi? appApi,
    this.stepTimeout = const Duration(seconds: 10),
  }) : _appApi = appApi ?? AppApi();

  final AppApi _appApi;
  final Duration stepTimeout;

  Future<StartupResult> initialize() async {
    final issues = <StartupIssue>[];
    var privacyAccepted = false;
    FirebaseAnalytics? analytics;

    await _setStartupTags();

    await _runStep(
      step: StartupStep.firebase,
      issues: issues,
      action: () async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          true,
        );
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        analytics = FirebaseAnalytics.instance;
      },
    );

    await _runStep(
      step: StartupStep.appInit,
      issues: issues,
      action: () => _appApi.initApp(),
    );

    await _runStep(
      step: StartupStep.hiveInit,
      issues: issues,
      action: () => Hive.initFlutter(),
    );

    await _runStep(
      step: StartupStep.hiveOpenBox,
      issues: issues,
      action: () => Hive.openBox('user_cars'),
    );

    await _runStep(
      step: StartupStep.prefs,
      issues: issues,
      action: () async {
        final prefs = await SharedPreferences.getInstance();
        privacyAccepted = prefs.getBool('privacy_accepted') ?? false;
      },
    );

    return StartupResult(
      privacyAccepted: privacyAccepted,
      analytics: analytics,
      issues: issues,
    );
  }

  Future<void> _setStartupTags() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final platformName = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    await Sentry.configureScope((scope) {
      scope.setTag('startup_platform', platformName);
      scope.setTag('startup_app_version', packageInfo.version);
      scope.setTag('startup_build_number', packageInfo.buildNumber);
    });
  }

  Future<void> _runStep({
    required StartupStep step,
    required List<StartupIssue> issues,
    required Future<void> Function() action,
  }) async {
    final stepName = step.name;
    await _recordStepState(stepName, 'start');

    try {
      await action().timeout(
        stepTimeout,
        onTimeout: () => throw StartupTimeoutException(step, stepTimeout),
      );
      await _recordStepState(stepName, 'ok');
    } on StartupTimeoutException catch (error, stackTrace) {
      issues.add(
        StartupIssue(
          step: step,
          isTimeout: true,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      await _recordFailure(
        stepName: stepName,
        state: 'timeout',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      issues.add(
        StartupIssue(
          step: step,
          isTimeout: false,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      await _recordFailure(
        stepName: stepName,
        state: 'error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _recordStepState(String step, String state) async {
    await Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'startup',
        message: '$step:$state',
        level: SentryLevel.info,
      ),
    );

    await Sentry.configureScope((scope) {
      scope.setTag('startup_step', step);
      scope.setTag('startup_state', state);
    });

    if (Firebase.apps.isNotEmpty) {
      await FirebaseCrashlytics.instance.setCustomKey('startup_step', step);
      await FirebaseCrashlytics.instance.setCustomKey('startup_state', state);
    }
  }

  Future<void> _recordFailure({
    required String stepName,
    required String state,
    required Object error,
    required StackTrace? stackTrace,
  }) async {
    await _recordStepState(stepName, state);

    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('startup_step', stepName);
        scope.setTag('startup_state', state);
      },
    );

    if (Firebase.apps.isNotEmpty) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: false,
        reason: 'startup:$stepName:$state',
      );
    } else {
      debugPrint(
        'Startup failure before Firebase init: $stepName:$state $error',
      );
    }
  }
}
