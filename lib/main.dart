
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/crash_reporter.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashReporter.record(
      details.exception,
      details.stack,
      reason: 'flutter',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    CrashReporter.record(
      error,
      stack,
      reason: 'platform',
    );
    return true;
  };

  // Show a calm message instead of the red error screen in release builds.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const Material(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Something went wrong on this screen. Please go back and try again.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );

    if (!AppConfig.isSecureApi) {
      CrashReporter.record(
        StateError(
          'API_BASE_URL is not https: ${AppConfig.apiBaseUrl}',
        ),
        null,
        reason: 'config',
      );
    }
  }

  final prefs = await SharedPreferences.getInstance();

  // TEMPORARY: Reset onboarding so the welcome screen appears for testing.
  await prefs.remove('naijamart_onboarding_seen');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NaijaMartApp(),
    ),
  );
}
