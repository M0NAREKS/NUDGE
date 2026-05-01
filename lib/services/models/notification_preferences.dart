class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = false,
    this.mealReminders = true,
    this.workoutReminders = true,
    this.dailyCheckIn = true,
    this.smartNudges = true,
    this.premiumCampaigns = false,
  });

  const NotificationPreferences.disabled()
    : enabled = false,
      mealReminders = true,
      workoutReminders = true,
      dailyCheckIn = true,
      smartNudges = true,
      premiumCampaigns = false;

  final bool enabled;
  final bool mealReminders;
  final bool workoutReminders;
  final bool dailyCheckIn;
  final bool smartNudges;
  final bool premiumCampaigns;

  bool get hasAnyCategoryEnabled {
    return mealReminders ||
        workoutReminders ||
        dailyCheckIn ||
        smartNudges ||
        premiumCampaigns;
  }

  NotificationPreferences copyWith({
    bool? enabled,
    bool? mealReminders,
    bool? workoutReminders,
    bool? dailyCheckIn,
    bool? smartNudges,
    bool? premiumCampaigns,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      mealReminders: mealReminders ?? this.mealReminders,
      workoutReminders: workoutReminders ?? this.workoutReminders,
      dailyCheckIn: dailyCheckIn ?? this.dailyCheckIn,
      smartNudges: smartNudges ?? this.smartNudges,
      premiumCampaigns: premiumCampaigns ?? this.premiumCampaigns,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'mealReminders': mealReminders,
      'workoutReminders': workoutReminders,
      'dailyCheckIn': dailyCheckIn,
      'smartNudges': smartNudges,
      'premiumCampaigns': premiumCampaigns,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const NotificationPreferences.disabled();
    }

    return NotificationPreferences(
      enabled: data['enabled'] as bool? ?? false,
      mealReminders: data['mealReminders'] as bool? ?? true,
      workoutReminders: data['workoutReminders'] as bool? ?? true,
      dailyCheckIn: data['dailyCheckIn'] as bool? ?? true,
      smartNudges: data['smartNudges'] as bool? ?? true,
      premiumCampaigns: data['premiumCampaigns'] as bool? ?? false,
    );
  }

  bool allowsType(String? rawType) {
    if (!enabled) return false;

    switch ((rawType ?? '').trim().toLowerCase()) {
      case 'meal':
      case 'meal_reminder':
      case 'nutrition':
        return mealReminders;
      case 'workout':
      case 'workout_reminder':
      case 'training':
        return workoutReminders;
      case 'daily':
      case 'checkin':
      case 'daily_check_in':
      case 'daily_checkin':
      case 'reminder':
        return dailyCheckIn;
      case 'smart_nudge':
      case 'nudge':
        return smartNudges;
      case 'premium':
      case 'campaign':
      case 'premium_campaign':
      case 'marketing':
        return premiumCampaigns;
      case 'general':
      default:
        return true;
    }
  }
}
