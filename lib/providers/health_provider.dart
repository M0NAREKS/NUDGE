import 'package:flutter/foundation.dart';

import '../services/models/workout_plan.dart';
import 'user_provider.dart';

class HealthProvider extends ChangeNotifier {
  AppUserProfile? _userProfile;
  double _bmr = 0;
  double _dailyCalories = 0;

  double get bmr => _bmr;
  double get dailyCalories => _dailyCalories;
  AppUserProfile? get userProfile => _userProfile;

  void syncUser(UserProvider userProvider) {
    syncProfile(userProvider.profile);
  }

  void syncProfile(AppUserProfile? profile) {
    _userProfile = profile;
    _recalculate();
  }

  @visibleForTesting
  static double activityMultiplier(String? activity) {
    switch (activity?.toLowerCase()) {
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'active':
        return 1.725;
      case 'athlete':
      case 'very_active':
        return 1.9;
      case 'sedentary':
      case 'none':
      default:
        return 1.2;
    }
  }

  @visibleForTesting
  static double calculateBmr({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    }

    return (10 * weight) + (6.25 * height) - (5 * age) - 161;
  }

  void _recalculate() {
    final profile = _userProfile;
    if (profile == null) {
      _bmr = 0;
      _dailyCalories = 0;
      notifyListeners();
      return;
    }

    final weight = profile.weight;
    final height = profile.height;
    final age = profile.resolvedAge;
    final gender = profile.gender;

    if (weight == null || height == null || age == null || gender == null) {
      _bmr = 0;
      _dailyCalories = 0;
      notifyListeners();
      return;
    }

    _bmr = calculateBmr(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );
    _dailyCalories = _bmr * activityMultiplier(profile.activity);
    notifyListeners();
  }

  Future<void> saveProfile(UserProvider userProvider) async {
    if (_userProfile == null) {
      syncUser(userProvider);
    }

    await userProvider.updateProfile(
      bmr: _bmr,
      dailyCalories: _dailyCalories,
    );
  }

  DailyWorkoutRecommendation workoutRecommendation({
    required double consumedCalories,
  }) {
    final profile = _userProfile;
    final targetCalories = profile?.dailyCalories ?? _dailyCalories;
    final activity = profile?.activity?.toLowerCase();
    final calorieDelta = consumedCalories - targetCalories;

    final primaryPlan = switch (activity) {
      'active' || 'athlete' || 'very_active' => const WorkoutPlan(
          planId: 'fireline',
          title: 'Fireline Performance',
          subtitle: 'Explosive intervals with a lower-body strength focus.',
          intensity: 'High',
          durationMinutes: 38,
          estimatedBurn: 360,
          mediaItems: [
            WorkoutMediaItem(
              title: 'Lower-body strength circuit',
              youtubeVideoId: 'ml6cT4AZdqI',
              durationLabel: '18 min',
              focusArea: 'Lower body',
              fallbackUrl: 'https://www.youtube.com/watch?v=ml6cT4AZdqI',
            ),
          ],
          blocks: [
            '6 min dynamic warm-up and ankle activation',
            '4 x 4 min incline walk or rower drive intervals',
            '3 rounds of split squats, push-ups and mountain climbers',
            '6 min cooldown and breathing reset',
          ],
        ),
      'moderate' => const WorkoutPlan(
          planId: 'orbit',
          title: 'Orbit Strength Circuit',
          subtitle: 'A balanced full-body session focused on posture and stability.',
          intensity: 'Medium',
          durationMinutes: 32,
          estimatedBurn: 280,
          mediaItems: [
            WorkoutMediaItem(
              title: 'Full-body strength flow',
              youtubeVideoId: 'UItWltVZZmE',
              durationLabel: '20 min',
              focusArea: 'Full body',
              fallbackUrl: 'https://www.youtube.com/watch?v=UItWltVZZmE',
            ),
          ],
          blocks: [
            '5 min mobility and shoulder prep',
            '3 rounds of goblet squats, hinge, push and plank',
            '8 min brisk incline walking finisher',
            '4 min cooldown stretch',
          ],
        ),
      _ => const WorkoutPlan(
          planId: 'ignition',
          title: 'Ignition Starter Session',
          subtitle: 'Low-impact calorie burn that wakes up the whole body.',
          intensity: 'Low-Medium',
          durationMinutes: 24,
          estimatedBurn: 190,
          mediaItems: [
            WorkoutMediaItem(
              title: 'Beginner low-impact routine',
              youtubeVideoId: 'gC_L9qAHVJ8',
              durationLabel: '15 min',
              focusArea: 'Beginner',
              fallbackUrl: 'https://www.youtube.com/watch?v=gC_L9qAHVJ8',
            ),
          ],
          blocks: [
            '4 min marching in place with arm swings',
            '3 rounds of sit-to-stand, wall push-ups and step touch',
            '8 min brisk walk or cycling',
            '4 min mobility cooldown',
          ],
        ),
    };

    WorkoutPlan? extraPlan;
    String summaryLine;

    if (calorieDelta > 120) {
      final extraMinutes = (calorieDelta / 12).round().clamp(12, 36);
      final extraBurn = (calorieDelta * 0.75).round().clamp(100, 320);
      extraPlan = WorkoutPlan(
        planId: 'afterburn',
        title: 'Afterburn Reset',
        subtitle: 'A short recovery session to offset today\'s calorie surplus.',
        intensity: calorieDelta > 320 ? 'High' : 'Medium',
        durationMinutes: extraMinutes,
        estimatedBurn: extraBurn,
        mediaItems: const [
          WorkoutMediaItem(
            title: 'Short compensation finisher',
            youtubeVideoId: 'UBMk30rjy0o',
            durationLabel: '12 min',
            focusArea: 'Conditioning',
            fallbackUrl: 'https://www.youtube.com/watch?v=UBMk30rjy0o',
          ),
        ],
        blocks: const [
          '2 min rope skips or marching warm-up',
          '6 rounds of 40 sec active / 20 sec rest intervals',
          '3 rounds of squat pulses, high knees and plank taps',
          '3 min breathing-based cooldown',
        ],
        reason:
            '${calorieDelta.toStringAsFixed(0)} kcal surplus detected. An extra reset session is ready.',
      );
      summaryLine =
          'You are above target today. An extra reset session was added after the main plan.';
    } else if (calorieDelta < -180) {
      summaryLine =
          'Your calorie deficit is clear. Keep the main plan controlled and skip the extra session.';
    } else {
      summaryLine =
          'Your calorie balance is stable. The main workout is enough for today.';
    }

    return DailyWorkoutRecommendation(
      targetCalories: targetCalories,
      consumedCalories: consumedCalories,
      calorieDelta: calorieDelta,
      summaryLine: summaryLine,
      primaryPlan: primaryPlan,
      extraPlan: extraPlan,
    );
  }
}
