import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_result.dart';
import '../models/sync_metadata.dart';
import '../models/user_profile.dart';
import 'auth_api_service.dart';

class AuthService extends ChangeNotifier {
  static const _profileKey = 'user_profile';
  static const _tokenKey = 'access_token';
  static const _guestKey = 'is_guest';

  final SharedPreferences _prefs;
  final AuthApiService _authApi;

  bool _isLoggedIn = false;
  bool _isGuest = false;
  UserProfile? _profile;
  String? _accessToken;

  AuthService(this._prefs, {AuthApiService? authApi})
      : _authApi = authApi ?? AuthApiService() {
    _loadUser();
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  UserProfile? get profile => _profile;
  String? get accessToken => _accessToken;
  String get userName => _profile?.fullName ?? '';
  String get userEmail => _profile?.email ?? '';

  void _loadUser() {
    _isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;
    _isGuest = _prefs.getBool(_guestKey) ?? false;
    _accessToken = _prefs.getString(_tokenKey);

    final rawProfile = _prefs.getString(_profileKey);
    if (rawProfile != null) {
      _profile = UserProfile.fromJson(
        json.decode(rawProfile) as Map<String, dynamic>,
      );
      return;
    }

    final legacyName = _prefs.getString('userName') ?? '';
    final legacyEmail = _prefs.getString('userEmail') ?? '';
    if (legacyName.isNotEmpty || legacyEmail.isNotEmpty) {
      _profile = UserProfile(
        email: legacyEmail,
        fullName: legacyName,
        sync: SyncMetadata(
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
        ),
      );
    }
  }

  Future<void> _saveProfile(UserProfile profile) async {
    _profile = profile;
    await _prefs.setString(_profileKey, json.encode(profile.toJson()));
    await _prefs.setString('userName', profile.fullName);
    await _prefs.setString('userEmail', profile.email);
  }

  Future<void> _saveToken(String? token) async {
    _accessToken = token;
    if (token == null || token.isEmpty) {
      await _prefs.remove(_tokenKey);
    } else {
      await _prefs.setString(_tokenKey, token);
    }
  }

  Future<AuthResult> _completeAuthenticatedSession({
    required String token,
  }) async {
    final me = await _authApi.me(token: token);
    if (me == null) {
      return const AuthResult.failure(AuthFailure.backendUnavailable);
    }

    _isLoggedIn = true;
    _isGuest = false;
    await _prefs.setBool('isLoggedIn', true);
    await _prefs.setBool(_guestKey, false);
    await _saveToken(token);
    await _saveProfile(
      UserProfile(
        id: me['id'] as String?,
        email: me['email'] as String? ?? '',
        fullName: me['full_name'] as String? ?? '',
        dailyStreak: me['daily_streak'] as int? ?? 0,
        totalScore: me['total_score'] as int? ?? 0,
        sync: SyncMetadata(
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
        ),
      ),
    );
    notifyListeners();
    return const AuthResult.success();
  }

  Future<AuthResult> login(String email, String password) async {
    if (email.isEmpty || password.length < 6) {
      return const AuthResult.failure(AuthFailure.invalidInput);
    }

    final loginResult = await _authApi.login(
      email: email.trim(),
      password: password,
    );
    if (!loginResult.result.success) {
      return loginResult.result;
    }

    return _completeAuthenticatedSession(token: loginResult.token!);
  }

  Future<AuthResult> register(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.length < 6) {
      return const AuthResult.failure(AuthFailure.invalidInput);
    }

    final registerResult = await _authApi.register(
      fullName: name.trim(),
      email: email.trim(),
      password: password,
    );
    if (!registerResult.result.success) {
      return registerResult.result;
    }

    return _completeAuthenticatedSession(token: registerResult.token!);
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _isGuest = false;
    _accessToken = null;
    await _prefs.setBool('isLoggedIn', false);
    await _prefs.setBool(_guestKey, false);
    await _saveToken(null);
    notifyListeners();
  }

  Future<void> loginAsGuest() async {
    _isLoggedIn = true;
    _isGuest = true;
    await _prefs.setBool('isLoggedIn', true);
    await _prefs.setBool(_guestKey, true);
    await _saveToken(null);
    await _saveProfile(
      UserProfile(
        email: '',
        fullName: 'ضيف',
        sync: SyncMetadata.fresh(),
      ),
    );
    notifyListeners();
  }

  /// Validates stored JWT against the backend and refreshes profile from the database.
  Future<bool> refreshSessionIfLoggedIn() async {
    if (!_isLoggedIn || _isGuest || _accessToken == null) {
      return _isLoggedIn;
    }

    final me = await _authApi.me(token: _accessToken!);
    if (me == null) {
      await logout();
      return false;
    }

    await _saveProfile(
      UserProfile(
        id: me['id'] as String?,
        email: me['email'] as String? ?? '',
        fullName: me['full_name'] as String? ?? '',
        dailyStreak: me['daily_streak'] as int? ?? 0,
        totalScore: me['total_score'] as int? ?? 0,
        sync: SyncMetadata(
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
        ),
      ),
    );
    notifyListeners();
    return true;
  }
}
