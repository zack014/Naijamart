
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';
import 'screens/admin_screen.dart';
import 'screens/get_started_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';

class NaijaMartApp extends ConsumerWidget {
  const NaijaMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) {
        final media = MediaQuery.of(context);

        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.4,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const RootGate(),
    );
  }
}

/// Controls which screen appears when the app opens.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final seenWelcome = ref.watch(onboardingSeenProvider);

    // Wait until the saved authentication session is restored.
    if (auth.status == AuthStatus.unknown) {
      return const SplashScreen(key: ValueKey('splash'));
    }

    // Administrators always go directly to the admin dashboard.
    if (auth.isAuthenticated && auth.isAdmin) {
      return const AdminScreen(key: ValueKey('admin'));
    }

    // Show welcome to visitors who have not completed onboarding.
    if (!seenWelcome && !auth.isAuthenticated) {
      return const GetStartedScreen(key: ValueKey('welcome'));
    }

    // Customers and returning guests enter the shopping application.
    return const MainShell(key: ValueKey('shell'));
  }
}
