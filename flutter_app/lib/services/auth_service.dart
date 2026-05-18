import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final SharedPreferences _prefs;

  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';

  AuthService(this._prefs) {
    _loadUser();
  }

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;

  void _loadUser() {
    _isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;
    _userName = _prefs.getString('userName') ?? '';
    _userEmail = _prefs.getString('userEmail') ?? '';
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    // For now, use local authentication
    // In production, this would call the backend API
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    if (email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      _userEmail = email;
      _userName = email.split('@').first;

      await _prefs.setBool('isLoggedIn', true);
      await _prefs.setString('userName', _userName);
      await _prefs.setString('userEmail', _userEmail);

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      _userName = name;
      _userEmail = email;

      await _prefs.setBool('isLoggedIn', true);
      await _prefs.setString('userName', _userName);
      await _prefs.setString('userEmail', _userEmail);

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';

    await _prefs.setBool('isLoggedIn', false);
    await _prefs.remove('userName');
    await _prefs.remove('userEmail');

    notifyListeners();
  }

  Future<void> loginAsGuest() async {
    _isLoggedIn = true;
    _userName = 'ضيف';
    _userEmail = '';

    await _prefs.setBool('isLoggedIn', true);
    await _prefs.setString('userName', _userName);

    notifyListeners();
  }
}
