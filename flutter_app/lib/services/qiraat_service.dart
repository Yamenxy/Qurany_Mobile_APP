import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QiraatService extends ChangeNotifier {
  static const String _storageKey = 'selected_qiraat';
  final SharedPreferences _prefs;

  String _selectedQiraat = 'حفص';

  QiraatService(this._prefs) {
    _loadQiraat();
  }

  String get selectedQiraat => _selectedQiraat;

  bool get isBazzi => _selectedQiraat == 'البزي';

  /// Backend `/api/v1/analyze` riwayah query value.
  String get riwayah => isBazzi ? 'bazzi' : 'hafs';

  /// Alias used by AI analysis wiring.
  String get backendRiwayah => riwayah;

  bool get isBazziSelected => isBazzi;

  /// Map UI qira'a label to backend riwayah id.
  static String riwayahFromQiraat(String qiraat) =>
      qiraat == 'البزي' ? 'bazzi' : 'hafs';

  void _loadQiraat() {
    _selectedQiraat = _prefs.getString(_storageKey) ?? 'حفص';
  }

  Future<void> setQiraat(String qiraat) async {
    _selectedQiraat = qiraat;
    await _prefs.setString(_storageKey, qiraat);
    notifyListeners();
  }
}
