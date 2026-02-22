import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user settings (max heart rate, FTP) via SharedPreferences.
class UserSettingsService {
  static const String _maxHeartRateKey = 'user_max_heart_rate';
  static const String _ftpKey = 'user_ftp';

  final SharedPreferences _prefs;

  /// Production constructor — use [create] + [init] instead.
  @visibleForTesting
  UserSettingsService(this._prefs);

  /// Factory that creates an uninitialized instance. Call [init] before use.
  static UserSettingsService? _instance;

  static Future<UserSettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = UserSettingsService(prefs);
    return _instance!;
  }

  int? get maxHeartRate => _prefs.getInt(_maxHeartRateKey);

  set maxHeartRate(int? value) {
    if (value == null) {
      _prefs.remove(_maxHeartRateKey);
    } else {
      _prefs.setInt(_maxHeartRateKey, value);
    }
  }

  int? get ftp => _prefs.getInt(_ftpKey);

  set ftp(int? value) {
    if (value == null) {
      _prefs.remove(_ftpKey);
    } else {
      _prefs.setInt(_ftpKey, value);
    }
  }
}
