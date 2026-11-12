
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider not overridden',
  ),
);

/// Selected tab in the main shell.
final navIndexProvider = StateProvider<int>((ref) => 0);

abstract class NavTab {
  static const home = 0;
  static const saved = 1;
  static const cart = 2;
  static const orders = 3;
  static const account = 4;
}

/// Tracks whether the welcome screen has been completed.
final onboardingSeenProvider =
    StateNotifierProvider<OnboardingController, bool>((ref) {
  return OnboardingController(
    ref.watch(sharedPreferencesProvider),
  );
});

class OnboardingController extends StateNotifier<bool> {
  OnboardingController(this._prefs)
      : super(_prefs.getBool(_key) ?? false);

  static const String _key = 'naijamart_onboarding_seen';

  final SharedPreferences _prefs;

  /// Save that the welcome screen has been completed.
  Future<void> markSeen() async {
    state = true;
    await _prefs.setBool(_key, true);
  }

  /// Reset onboarding so the welcome screen can appear again.
  Future<void> resetSeen() async {
    await _prefs.remove(_key);
    state = false;
  }
}
