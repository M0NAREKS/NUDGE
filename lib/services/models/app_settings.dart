import 'package:flutter/material.dart';

import 'notification_preferences.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeCode = 'tr',
    this.coachMode = 'balanced coach',
    this.notificationPreferences = const NotificationPreferences.disabled(),
  });

  final ThemeMode themeMode;
  final String localeCode;
  final String coachMode;
  final NotificationPreferences notificationPreferences;

  Locale get locale => Locale(localeCode);

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    String? coachMode,
    NotificationPreferences? notificationPreferences,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      coachMode: coachMode ?? this.coachMode,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'localeCode': localeCode,
      'coachMode': coachMode,
      'notificationPreferences': notificationPreferences.toMap(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const AppSettings();
    }

    return AppSettings(
      themeMode: _themeModeFromName(data['themeMode'] as String?),
      localeCode: (data['localeCode'] as String?)?.trim().isNotEmpty == true
          ? (data['localeCode'] as String).trim()
          : 'tr',
      coachMode: (data['coachMode'] as String?)?.trim().isNotEmpty == true
          ? (data['coachMode'] as String).trim()
          : 'balanced coach',
      notificationPreferences: NotificationPreferences.fromMap(
        data['notificationPreferences'] as Map<String, dynamic>?,
      ),
    );
  }

  static ThemeMode _themeModeFromName(String? rawValue) {
    switch ((rawValue ?? '').trim().toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
