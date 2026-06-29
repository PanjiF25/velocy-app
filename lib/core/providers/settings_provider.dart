import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  factory SettingsProvider() => _instance;
  SettingsProvider._internal();

  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('en', 'US');
  
  bool _pushNotificationsEnabled = true;
  bool _taskAlertsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get taskAlertsEnabled => _taskAlertsEnabled;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
    }
  }

  void togglePushNotifications() {
    _pushNotificationsEnabled = !_pushNotificationsEnabled;
    notifyListeners();
  }

  void toggleTaskAlerts() {
    _taskAlertsEnabled = !_taskAlertsEnabled;
    notifyListeners();
  }
}
