import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/food_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/models/daily_nutrition_summary.dart';
import '../../services/models/workout_plan.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({
    super.key,
    this.embedded = false,
    this.enableEmbeddedMedia = true,
  });

  final bool embedded;
  final bool enableEmbeddedMedia;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().profile;
    final healthProvider = context.watch<HealthProvider>();
    final foodProvider = context.read<FoodProvider>();
    final l10n = context.l10n;
    final palette = context.palette;
    final embeddedBottomSpacing = embedded
        ? MediaQuery.paddingOf(context).bottom + 108.0
        : 0.0;

    if (user == null) {
      final empty = Center(child: Text(l10n.t('workout_title')));
      return embedded ? empty : Scaffold(body: empty);
    }

    final content = StreamBuilder<DailyNutritionSummary>(
      stream: foodProvider.summaryForToday(user.uid),
      builder: (context, snapshot) {
        final summary = snapshot.data ?? const DailyNutritionSummary.empty();
        final recommendation = healthProvider.workoutRecommendation(
          consumedCalories: summary.calories,
        );

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  24 + embeddedBottomSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WorkoutHero(recommendation: recommendation),
                    const SizedBox(height: 16),
                    _CalorieBalanceCard(recommendation: recommendation),
                    const SizedBox(height: 16),
                    _WorkoutPlanCard(
                      title: l10n.t('daily_plan'),
                      plan: recommendation.primaryPlan,
                      highlight: _localizedSummary(
                        l10n,
                        recommendation.calorieDelta,
                      ),
                    ),
                    if (enableEmbeddedMedia &&
                        recommendation.primaryPlan.mediaItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _WorkoutVideoCard(
                        planId: recommendation.primaryPlan.planId,
                        media: recommendation.primaryPlan.mediaItems.first,
                      ),
                    ],
                    if (recommendation.extraPlan != null) ...[
                      const SizedBox(height: 16),
                      _WorkoutPlanCard(
                        title: l10n.t('extra_session'),
                        plan: recommendation.extraPlan!,
                        highlight: l10n.t(
                          'afterburn_reason',
                          params: {
                            'calories': recommendation.calorieDelta
                                .toStringAsFixed(0),
                          },
                        ),
                        fiery: true,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _RecoveryCard(calorieDelta: recommendation.calorieDelta),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(l10n.t('workout_title'))),
      body: SafeArea(child: content),
    );
  }

  String _localizedSummary(AppLocalizations l10n, double calorieDelta) {
    if (calorieDelta > 120) return l10n.t('balance_high');
    if (calorieDelta < -180) return l10n.t('balance_low');
    return l10n.t('balance_stable');
  }
}

class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero({required this.recommendation});

  final DailyWorkoutRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.alpha(palette.shadow, 0.6),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('workout_hero_title'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: palette.onPanelMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.t('workout_hero_subtitle_clean'),
            style: TextStyle(
              color: palette.onPanel,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.t('workout_hero_desc'),
            style: TextStyle(color: palette.onPanelMuted, height: 1.35),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                label: l10n.t('target'),
                value:
                    '${recommendation.targetCalories.toStringAsFixed(0)} kcal',
              ),
              _HeroChip(
                label: l10n.t('consumed'),
                value:
                    '${recommendation.consumedCalories.toStringAsFixed(0)} kcal',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.alpha(palette.onPanel, 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.alpha(palette.onPanel, 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.alpha(palette.onPanel, 0.68),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.onPanel,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieBalanceCard extends StatelessWidget {
  const _CalorieBalanceCard({required this.recommendation});

  final DailyWorkoutRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.alpha(AppColors.info, 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.insights_rounded, color: AppColors.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('calorie_deficit'),
                  style: TextStyle(
                    color: palette.onPanelMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${recommendation.calorieDelta.abs().toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    color: palette.onPanel,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation.calorieDelta > 120
                      ? l10n.t('balance_high')
                      : recommendation.calorieDelta < -180
                      ? l10n.t('balance_low')
                      : l10n.t('balance_stable'),
                  style: TextStyle(
                    color: palette.onPanelMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutPlanCard extends StatelessWidget {
  const _WorkoutPlanCard({
    required this.title,
    required this.plan,
    required this.highlight,
    this.fiery = false,
  });

  final String title;
  final WorkoutPlan plan;
  final String highlight;
  final bool fiery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final localizedTitle = l10n.workoutPlanTitle(plan.planId, plan.title);
    final localizedSubtitle = l10n.workoutPlanSubtitle(
      plan.planId,
      plan.subtitle,
    );
    final localizedBlocks = l10n.workoutPlanBlocks(plan.planId, plan.blocks);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: fiery
              ? AppColors.alpha(AppColors.secondary, 0.24)
              : palette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localizedTitle,
            style: TextStyle(
              color: palette.onPanel,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizedSubtitle,
            style: TextStyle(
              color: palette.onPanelMuted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TagPill(
                label: l10n.durationMinutesLabel(plan.durationMinutes),
                color: AppColors.alpha(AppColors.secondary, 0.12),
              ),
              _TagPill(
                label: '${plan.estimatedBurn} kcal',
                color: AppColors.alpha(AppColors.info, 0.12),
              ),
              _TagPill(
                label: l10n.intensityLabel(plan.intensity),
                color: AppColors.alpha(AppColors.accent, 0.14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.panelSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              highlight,
              style: TextStyle(
                color: palette.onPanel,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final block in localizedBlocks) ...[
            _PlanLine(text: block),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _WorkoutVideoCard extends StatefulWidget {
  const _WorkoutVideoCard({required this.planId, required this.media});

  final String planId;
  final WorkoutMediaItem media;

  @override
  State<_WorkoutVideoCard> createState() => _WorkoutVideoCardState();
}

class _WorkoutVideoCardState extends State<_WorkoutVideoCard> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.media.youtubeVideoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('video_title'),
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.workoutMediaTitle(widget.planId, widget.media.title),
            style: TextStyle(
              color: palette.onPanel,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagPill(
                label: widget.media.durationLabel,
                color: AppColors.alpha(AppColors.secondary, 0.12),
              ),
              _TagPill(
                label: l10n.workoutMediaFocus(
                  widget.planId,
                  widget.media.focusArea,
                ),
                color: AppColors.alpha(AppColors.accent, 0.14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.t('video_fallback'),
            style: TextStyle(color: palette.onPanelMuted, height: 1.35),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(widget.media.fallbackUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(l10n.t('video_open_youtube')),
          ),
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.calorieDelta});

  final double calorieDelta;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final tags = <String>[
      l10n.t('recovery_mobility'),
      l10n.t('recovery_sleep'),
      l10n.t('recovery_hydration'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.alpha(AppColors.ember, 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: AppColors.ember,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.t('recovery_title_clean'),
                  style: TextStyle(
                    color: palette.onPanel,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t('recovery_desc'),
            style: TextStyle(color: palette.onPanelMuted, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((item) => _TagPill(label: item, color: palette.panelSoft))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: palette.onPanel, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 8, color: AppColors.ember),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: palette.onPanel,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
