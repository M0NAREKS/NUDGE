import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';
import '../services/models/app_settings.dart';
import '../services/models/notification_preferences.dart';
import '../services/notification_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider({required NotificationService notificationService})
    : _notificationService = notificationService;

  final NotificationService _notificationService;

  AppSettings _settings = const AppSettings();
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _loaded;
  ThemeMode get themeMode => _settings.themeMode;
  Locale get locale => _settings.locale;
  String get localeCode => _settings.localeCode;
  String get coachMode => _settings.coachMode;
  NotificationPreferences get notificationPreferences =>
      _settings.notificationPreferences;

  Future<void> initialize() async {
    _settings = await LocalStorageService.getAppSettings();
    _loaded = true;
    notifyListeners();
    await _notificationService.syncPreferenceDrivenNotifications(
      preferences: _settings.notificationPreferences,
      localeCode: _settings.localeCode,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _persist();
  }

  Future<void> setLocaleCode(String localeCode) async {
    _settings = _settings.copyWith(localeCode: localeCode);
    await _persist();
    await _notificationService.syncPreferenceDrivenNotifications(
      preferences: _settings.notificationPreferences,
      localeCode: _settings.localeCode,
    );
  }

  Future<void> setCoachMode(String mode) async {
    _settings = _settings.copyWith(coachMode: mode);
    await _persist();
  }

  Future<bool> setNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    final previous = _settings;
    final enablingNotifications =
        preferences.enabled && !_settings.notificationPreferences.enabled;
    _settings = _settings.copyWith(notificationPreferences: preferences);
    final synced = await _notificationService.syncPreferenceDrivenNotifications(
      preferences: preferences,
      localeCode: _settings.localeCode,
      requestPermissionIfNeeded: enablingNotifications,
    );
    if (!synced) {
      _settings = previous;
      notifyListeners();
      return false;
    }

    await _persist();
    return true;
  }

  Future<void> _persist() async {
    await LocalStorageService.saveAppSettings(_settings);
    notifyListeners();
  }

  Future<bool> showTestNotification() async {
    if (!_settings.notificationPreferences.enabled) {
      return false;
    }
    return _notificationService.showTestReminder(
      localeCode: _settings.localeCode,
      requestPermissionIfNeeded: true,
    );
  }
}
