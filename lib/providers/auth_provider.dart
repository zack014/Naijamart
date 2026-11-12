import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/errors.dart';
import '../models/app_user.dart';
import '../services/store_api.dart';
import 'app_providers.dart';

enum AuthStatus { unknown, authenticated, guest }

@immutable
class AuthState {
  const AuthState._(this.status, this.user, this.notice);

  const AuthState.unknown() : this._(AuthStatus.unknown, null, null);
  const AuthState.guest({String? notice}) : this._(AuthStatus.guest, null, notice);
  const AuthState.authenticated(AppUser user)
      : this._(AuthStatus.authenticated, user, null);

  final AuthStatus status;
  final AppUser? user;

  /// One-off message to show the person (e.g. "session expired").
  final String? notice;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdmin => user?.isAdmin ?? false;
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    api: ref.watch(storeApiProvider),
    client: ref.watch(apiClientProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required StoreApi api,
    required ApiClient client,
    required SharedPreferences prefs,
  })  : _api = api,
        _client = client,
        _prefs = prefs,
        super(const AuthState.unknown()) {
    _client.onUnauthorized = _handleExpired;
    restore();
  }

  static const _userKey = 'naijamart_cached_user';

  final StoreApi _api;
  final ApiClient _client;
  final SharedPreferences _prefs;

  /// Restores the previous session on launch.
  Future<void> restore() async {
    final token = await _client.readToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      state = const AuthState.guest();
      return;
    }
    try {
      final user = await _api.currentUser();
      if (!mounted) return;
      await _cacheUser(user);
      state = AuthState.authenticated(user);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        state = const AuthState.guest();
        return;
      }
      // Offline or server hiccup: stay signed in using the last known profile.
      final cached = _cachedUser();
      state = cached != null
          ? AuthState.authenticated(cached)
          : const AuthState.guest();
    }
  }

  Future<void> login(String email, String password) async {
    final user = await _api.login(email, password);
    await _cacheUser(user);
    if (mounted) state = AuthState.authenticated(user);
  }

  Future<void> register(String name, String email, String password) async {
    final user = await _api.register(name, email, password);
    await _cacheUser(user);
    if (mounted) state = AuthState.authenticated(user);
  }

  Future<void> logout() async {
    await _api.logout();
    await _prefs.remove(_userKey);
    if (mounted) state = const AuthState.guest();
  }

  Future<void> deleteAccount() async {
    await _api.deleteAccount();
    await _prefs.remove(_userKey);
    if (mounted) state = const AuthState.guest();
  }

  void clearNotice() {
    if (state.notice != null && mounted) state = const AuthState.guest();
  }

  void _handleExpired() {
    if (!mounted || !state.isAuthenticated) return;
    _prefs.remove(_userKey);
    state = const AuthState.guest(
      notice: 'Your session has expired. Please sign in again.',
    );
  }

  Future<void> _cacheUser(AppUser user) =>
      _prefs.setString(_userKey, jsonEncode(user.toJson()));

  AppUser? _cachedUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }
}
