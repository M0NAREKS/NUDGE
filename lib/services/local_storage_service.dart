import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_settings.dart';
import 'models/notification_preferences.dart';
import 'models/smart_nudge.dart';

class LocalStorageService {
  static const _emailKey = 'user_email';
  static const _firstNameKey = 'user_first_name';
  static const _lastNameKey = 'user_last_name';
  static const _genderKey = 'user_gender';
  static const _ageKey = 'user_age';
  static const _birthDateKey = 'user_birth_date';
  static const _heightKey = 'user_height';
  static const _weightKey = 'user_weight';
  static const _activityKey = 'user_activity';
  static const _coachModeKey = 'coach_mode';
  static const _themeModeKey = 'theme_mode';
  static const _localeCodeKey = 'locale_code';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _mealRemindersKey = 'notification_meal_reminders';
  static const _workoutRemindersKey = 'notification_workout_reminders';
  static const _dailyCheckInKey = 'notification_daily_check_in';
  static const _smartNudgesKey = 'notification_smart_nudges';
  static const _premiumCampaignsKey = 'notification_premium_campaigns';
  static const _smartNudgeHistoryKey = 'smart_nudge_history';

  static Future<void> saveUser({
    required String email,
    String? password,
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? birthDate,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    if (firstName != null) await prefs.setString(_firstNameKey, firstName);
    if (lastName != null) await prefs.setString(_lastNameKey, lastName);
    if (gender != null) await prefs.setString(_genderKey, gender);
    if (birthDate != null) {
      await prefs.setString(
        _birthDateKey,
        DateTime(
          birthDate.year,
          birthDate.month,
          birthDate.day,
        ).toIso8601String(),
      );
      await prefs.remove(_ageKey);
    }
    if (age != null) await prefs.setInt(_ageKey, age);
    if (height != null) await prefs.setDouble(_heightKey, height);
    if (weight != null) await prefs.setDouble(_weightKey, weight);
    if (activityLevel != null) {
      await prefs.setString(_activityKey, activityLevel);
    }
  }

  static Future<Map<String, dynamic>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_emailKey),
      'password': null,
      'firstName': prefs.getString(_firstNameKey),
      'lastName': prefs.getString(_lastNameKey),
      'gender': prefs.getString(_genderKey),
      'birthDate': prefs.getString(_birthDateKey),
      'age': prefs.getInt(_ageKey),
      'height': prefs.getDouble(_heightKey),
      'weight': prefs.getDouble(_weightKey),
      'activityLevel': prefs.getString(_activityKey),
    };
  }

  static Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? gender,
    DateTime? birthDate,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (firstName != null) await prefs.setString(_firstNameKey, firstName);
    if (lastName != null) await prefs.setString(_lastNameKey, lastName);
    if (gender != null) await prefs.setString(_genderKey, gender);
    if (birthDate != null) {
      await prefs.setString(
        _birthDateKey,
        DateTime(
          birthDate.year,
          birthDate.month,
          birthDate.day,
        ).toIso8601String(),
      );
      await prefs.remove(_ageKey);
    }
    if (age != null) await prefs.setInt(_ageKey, age);
    if (height != null) await prefs.setDouble(_heightKey, height);
    if (weight != null) await prefs.setDouble(_weightKey, weight);
    if (activityLevel != null) {
      await prefs.setString(_activityKey, activityLevel);
    }
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_firstNameKey);
    await prefs.remove(_lastNameKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_birthDateKey);
    await prefs.remove(_ageKey);
    await prefs.remove(_heightKey);
    await prefs.remove(_weightKey);
    await prefs.remove(_activityKey);
  }

  static Future<void> saveAppSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, settings.themeMode.name);
    await prefs.setString(_localeCodeKey, settings.localeCode);
    await prefs.setString(_coachModeKey, settings.coachMode);
    await prefs.setBool(
      _notificationsEnabledKey,
      settings.notificationPreferences.enabled,
    );
    await prefs.setBool(
      _mealRemindersKey,
      settings.notificationPreferences.mealReminders,
    );
    await prefs.setBool(
      _workoutRemindersKey,
      settings.notificationPreferences.workoutReminders,
    );
    await prefs.setBool(
      _dailyCheckInKey,
      settings.notificationPreferences.dailyCheckIn,
    );
    await prefs.setBool(
      _smartNudgesKey,
      settings.notificationPreferences.smartNudges,
    );
    await prefs.setBool(
      _premiumCampaignsKey,
      settings.notificationPreferences.premiumCampaigns,
    );
  }

  static Future<AppSettings> getAppSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return AppSettings(
      themeMode: _themeModeFromName(prefs.getString(_themeModeKey)),
      localeCode: prefs.getString(_localeCodeKey) ?? 'tr',
      coachMode: prefs.getString(_coachModeKey) ?? 'balanced coach',
      notificationPreferences: NotificationPreferences(
        enabled: prefs.getBool(_notificationsEnabledKey) ?? false,
        mealReminders: prefs.getBool(_mealRemindersKey) ?? true,
        workoutReminders: prefs.getBool(_workoutRemindersKey) ?? true,
        dailyCheckIn: prefs.getBool(_dailyCheckInKey) ?? true,
        smartNudges: prefs.getBool(_smartNudgesKey) ?? true,
        premiumCampaigns: prefs.getBool(_premiumCampaignsKey) ?? false,
      ),
    );
  }

  static Future<void> saveCoachMode(String mode) async {
    final settings = await getAppSettings();
    await saveAppSettings(settings.copyWith(coachMode: mode));
  }

  static Future<String> getCoachMode() async {
    final settings = await getAppSettings();
    return settings.coachMode;
  }

  static Future<NotificationPreferences> getNotificationPreferences() async {
    final settings = await getAppSettings();
    return settings.notificationPreferences;
  }

  static Future<SmartNudgeHistory> getSmartNudgeHistory(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_smartNudgeHistoryKey);
    if (raw == null || raw.trim().isEmpty) {
      return SmartNudgeHistory(dateKey: dateKey);
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final history = SmartNudgeHistory.fromMap(decoded);
      if (history.dateKey != dateKey) {
        return SmartNudgeHistory(dateKey: dateKey);
      }
      return history;
    } catch (_) {
      return SmartNudgeHistory(dateKey: dateKey);
    }
  }

  static Future<void> saveSmartNudgeHistory(SmartNudgeHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_smartNudgeHistoryKey, jsonEncode(history.toMap()));
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final settings = await getAppSettings();
    await saveAppSettings(settings.copyWith(themeMode: mode));
  }

  static Future<void> saveLocaleCode(String localeCode) async {
    final settings = await getAppSettings();
    await saveAppSettings(settings.copyWith(localeCode: localeCode));
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
