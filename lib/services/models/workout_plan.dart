class WorkoutMediaItem {
  const WorkoutMediaItem({
    required this.title,
    required this.youtubeVideoId,
    required this.durationLabel,
    required this.focusArea,
    required this.fallbackUrl,
  });

  final String title;
  final String youtubeVideoId;
  final String durationLabel;
  final String focusArea;
  final String fallbackUrl;

  String get thumbnailUrl => 'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg';
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.planId,
    required this.title,
    required this.subtitle,
    required this.intensity,
    required this.durationMinutes,
    required this.estimatedBurn,
    required this.blocks,
    this.reason,
    this.mediaItems = const <WorkoutMediaItem>[],
    this.ctaLabel,
  });

  final String planId;
  final String title;
  final String subtitle;
  final String intensity;
  final int durationMinutes;
  final int estimatedBurn;
  final List<String> blocks;
  final String? reason;
  final List<WorkoutMediaItem> mediaItems;
  final String? ctaLabel;
}

class DailyWorkoutRecommendation {
  const DailyWorkoutRecommendation({
    required this.targetCalories,
    required this.consumedCalories,
    required this.calorieDelta,
    required this.summaryLine,
    required this.primaryPlan,
    this.extraPlan,
  });

  final double targetCalories;
  final double consumedCalories;
  final double calorieDelta;
  final String summaryLine;
  final WorkoutPlan primaryPlan;
  final WorkoutPlan? extraPlan;

  bool get hasExtraPlan => extraPlan != null;
}
