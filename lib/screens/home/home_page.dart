import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/daily_insight_provider.dart';
import '../../providers/food_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/hydration_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/models/daily_hydration_summary.dart';
import '../../services/models/daily_insight.dart';
import '../../services/models/daily_nutrition_summary.dart';
import '../../services/models/food_item.dart';
import '../../utils/app_page_route.dart';
import '../../utils/app_routes.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';
import '../food/food_editor_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.embedded = false,
    this.onOpenFood,
    this.onOpenHydration,
    this.onOpenWorkout,
    this.onOpenCoach,
    this.onOpenProfile,
  });

  final bool embedded;
  final VoidCallback? onOpenFood;
  final VoidCallback? onOpenHydration;
  final VoidCallback? onOpenWorkout;
  final VoidCallback? onOpenCoach;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final healthProvider = context.watch<HealthProvider>();
    final foodProvider = context.read<FoodProvider>();
    final hydrationProvider = _tryRead<HydrationProvider>(context);
    final profile = userProvider.profile;
    final l10n = context.l10n;
    final palette = context.palette;
    final embeddedBottomSpacing = embedded
        ? MediaQuery.paddingOf(context).bottom + 108.0
        : 0.0;

    if (profile == null) {
      const loading = Center(child: CircularProgressIndicator());
      return embedded ? loading : const Scaffold(body: loading);
    }

    final targetCalories =
        profile.dailyCalories ?? healthProvider.dailyCalories;

    final content = StreamBuilder<DailyNutritionSummary>(
      stream: foodProvider.summaryForToday(profile.uid),
      builder: (context, summarySnapshot) {
        final summary =
            summarySnapshot.data ?? const DailyNutritionSummary.empty();
        final consumed = summary.calories;
        final remaining = (targetCalories - consumed)
            .clamp(0, targetCalories)
            .toDouble();
        final progress = targetCalories > 0
            ? (consumed / targetCalories).clamp(0, 1).toDouble()
            : 0.0;

        Widget buildDashboard(DailyHydrationSummary? hydrationSummary) {
          return StreamBuilder<List<FoodItem>>(
            stream: foodProvider.mealsForToday(profile.uid),
            builder: (context, mealSnapshot) {
              final meals = mealSnapshot.data ?? const <FoodItem>[];

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24 + embeddedBottomSpacing,
                ),
                children: [
                  _HeaderCard(
                    name: profile.name,
                    consumed: consumed,
                    remaining: remaining,
                    target: targetCalories,
                    progress: progress,
                    protein: summary.protein,
                    carbs: summary.carbs,
                    fat: summary.fat,
                  ),
                  const SizedBox(height: 16),
                  _DailyInsightSection(
                    profile: profile,
                    summary: summary,
                    meals: meals,
                    hydrationSummary: hydrationSummary,
                  ),
                  const SizedBox(height: 16),
                  _QuickActions(
                    onAddFood: () =>
                        (onOpenFood ??
                        () =>
                            Navigator.pushNamed(context, AppRoutes.addFood))(),
                    onHydration: () =>
                        (onOpenHydration ??
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.hydration,
                        ))(),
                    onWorkout: () =>
                        (onOpenWorkout ??
                        () =>
                            Navigator.pushNamed(context, AppRoutes.workout))(),
                    onCoachChat: () =>
                        (onOpenCoach ??
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.coachChat,
                        ))(),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatCard(
                            compact: compact,
                            icon: Icons.flag_rounded,
                            label: l10n.t('target'),
                            value: '${targetCalories.toStringAsFixed(0)} kcal',
                            badge: l10n.t('daily'),
                            accent: AppColors.info,
                          ),
                          _StatCard(
                            compact: compact,
                            icon: Icons.check_circle_rounded,
                            label: l10n.t('consumed'),
                            value: '${consumed.toStringAsFixed(0)} kcal',
                            badge: l10n.t('today'),
                            accent: AppColors.secondary,
                          ),
                          _StatCard(
                            compact: compact,
                            icon: Icons.av_timer,
                            label: l10n.t('remaining'),
                            value: '${remaining.toStringAsFixed(0)} kcal',
                            badge: l10n.t('tracking'),
                            accent: AppColors.accent,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _MacroSection(summary: summary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('today_meals'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: palette.onPanel,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (mealSnapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (meals.isEmpty)
                    const _EmptyMeals()
                  else ...[
                    for (final meal in meals) ...[
                      _MealCard(meal: meal),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              );
            },
          );
        }

        if (hydrationProvider == null) {
          return buildDashboard(null);
        }

        return StreamBuilder<DailyHydrationSummary>(
          stream: hydrationProvider.summaryForToday(
            profile.uid,
            profile: profile,
          ),
          builder: (context, hydrationSnapshot) {
            return buildDashboard(hydrationSnapshot.data);
          },
        );
      },
    );

    if (embedded) return content;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(l10n.t('app_name')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () =>
                (onOpenProfile ??
                () => Navigator.pushNamed(context, AppRoutes.profile))(),
          ),
        ],
      ),
      body: SafeArea(child: content),
    );
  }
}

T? _tryRead<T>(BuildContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
  }
}

T? _tryWatch<T>(BuildContext context) {
  try {
    return context.watch<T>();
  } catch (_) {
    return null;
  }
}

class _DailyInsightSection extends StatefulWidget {
  const _DailyInsightSection({
    required this.profile,
    required this.summary,
    required this.meals,
    required this.hydrationSummary,
  });

  final AppUserProfile profile;
  final DailyNutritionSummary summary;
  final List<FoodItem> meals;
  final DailyHydrationSummary? hydrationSummary;

  @override
  State<_DailyInsightSection> createState() => _DailyInsightSectionState();
}

class _DailyInsightSectionState extends State<_DailyInsightSection> {
  String? _lastRefreshSignature;

  @override
  Widget build(BuildContext context) {
    final provider = _tryWatch<DailyInsightProvider>(context);
    if (provider == null) {
      return const SizedBox.shrink();
    }

    final localeCode = context.l10n.locale.languageCode;
    final localInsight = provider.buildLocalInsight(
      profile: widget.profile,
      summary: widget.summary,
      meals: widget.meals,
      hydration: widget.hydrationSummary,
      localeCode: localeCode,
    );
    _scheduleRefresh(provider, localeCode, localInsight);

    final current = provider.current;
    final insight = current?.dateKey == localInsight.dateKey
        ? current!
        : localInsight;
    return _DailyInsightCard(insight: insight);
  }

  void _scheduleRefresh(
    DailyInsightProvider provider,
    String localeCode,
    DailyInsight localInsight,
  ) {
    final signature = [
      localInsight.dateKey,
      localeCode,
      widget.summary.calories.toStringAsFixed(1),
      widget.summary.protein.toStringAsFixed(1),
      widget.summary.carbs.toStringAsFixed(1),
      widget.summary.fat.toStringAsFixed(1),
      widget.hydrationSummary?.totalMl ?? 0,
      widget.hydrationSummary?.goalMl ?? 0,
      widget.meals
          .map((meal) => '${meal.id}:${meal.calories}:${meal.protein}')
          .join('|'),
    ].join('::');
    if (_lastRefreshSignature == signature) return;
    _lastRefreshSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      provider.refreshFromDailyData(
        profile: widget.profile,
        summary: widget.summary,
        meals: widget.meals,
        hydration: widget.hydrationSummary,
        localeCode: localeCode,
      );
    });
  }
}

class _DailyInsightCard extends StatelessWidget {
  const _DailyInsightCard({required this.insight});

  final DailyInsight insight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final accent = insight.recoveryMode
        ? AppColors.accent
        : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.alpha(accent, 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.alpha(accent, 0.34)),
                ),
                child: Text(
                  '${insight.consistencyScore}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('daily_insight_title'),
                      style: TextStyle(
                        color: palette.onPanel,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('consistency_score'),
                      style: TextStyle(
                        color: palette.onPanelMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (insight.recoveryMode)
                _InsightChip(
                  label: l10n.t('recovery_mode'),
                  color: AppColors.accent,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            insight.narrative,
            style: TextStyle(
              color: palette.onPanel,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _InsightLine(
            icon: Icons.check_circle_rounded,
            label: l10n.t('positive_signal'),
            value: insight.positiveSignal,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 8),
          _InsightLine(
            icon: Icons.warning_amber_rounded,
            label: l10n.t('risk_signal'),
            value: insight.riskSignal,
            color: AppColors.accent,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.alpha(AppColors.info, 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.alpha(AppColors.info, 0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.next_plan_rounded, color: AppColors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${l10n.t('tomorrow_action')}: ${insight.tomorrowAction}',
                    style: TextStyle(
                      color: palette.onPanel,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
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

class _InsightLine extends StatelessWidget {
  const _InsightLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(
              color: palette.onPanelMuted,
              height: 1.28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.alpha(color, 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.consumed,
    required this.remaining,
    required this.target,
    required this.progress,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String name;
  final double consumed;
  final double remaining;
  final double target;
  final double progress;
  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.alpha(palette.shadow, 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('home_daily_balance'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: palette.onPanelMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('home_greeting', params: {'name': name.split(' ').first}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.onPanel,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('home_summary'),
            style: TextStyle(
              color: palette.onPanelMuted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderPill(
                label: l10n.t('target'),
                value: '${target.toStringAsFixed(0)} kcal',
              ),
              _HeaderPill(
                label: l10n.t('remaining'),
                value: '${remaining.toStringAsFixed(0)} kcal',
              ),
              _HeaderPill(
                label: l10n.t('protein'),
                value: '${protein.toStringAsFixed(1)} g',
              ),
              _HeaderPill(
                label: l10n.t('carbs'),
                value: '${carbs.toStringAsFixed(1)} g',
              ),
              _HeaderPill(
                label: l10n.t('fat'),
                value: '${fat.toStringAsFixed(1)} g',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.alpha(palette.onPanel, 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.progressCompletedLabel((progress * 100).round()),
            style: TextStyle(
              color: palette.onPanel,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.consumedCaloriesLabel(consumed),
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

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.alpha(palette.onPanel, 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.alpha(palette.onPanel, 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.onPanelMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: palette.onPanel,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddFood,
    required this.onHydration,
    required this.onWorkout,
    required this.onCoachChat,
  });

  final VoidCallback onAddFood;
  final VoidCallback onHydration;
  final VoidCallback onWorkout;
  final VoidCallback onCoachChat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAddFood,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text(l10n.t('quick_add_food')),
          ),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.water_drop_rounded,
          label: l10n.t('quick_hydration'),
          onTap: onHydration,
          accentColor: AppColors.info,
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.fitness_center_rounded,
          label: l10n.t('quick_workout'),
          onTap: onWorkout,
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: l10n.t('quick_coach'),
          onTap: onCoachChat,
          accentColor: AppColors.ember,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentColor = AppColors.info,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: palette.panelElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: palette.onPanel,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.compact,
    required this.icon,
    required this.label,
    required this.value,
    required this.badge,
    required this.accent,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final String value;
  final String badge;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: compact ? double.infinity : 162,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.panelElevated,
          borderRadius: BorderRadius.circular(20),
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
                    color: AppColors.alpha(accent, 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.alpha(accent, 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: palette.onPanelMuted)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: palette.onPanel,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroSection extends StatelessWidget {
  const _MacroSection({required this.summary});

  final DailyNutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('macro_summary'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.onPanel,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MacroPill(
                label:
                    '${l10n.t('protein')}: ${summary.protein.toStringAsFixed(1)} g',
              ),
              _MacroPill(
                label:
                    '${l10n.t('carbs')}: ${summary.carbs.toStringAsFixed(1)} g',
              ),
              _MacroPill(
                label: '${l10n.t('fat')}: ${summary.fat.toStringAsFixed(1)} g',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        style: TextStyle(color: palette.onPanel, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_dining_rounded,
            size: 48,
            color: AppColors.ember,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t('no_meals_yet'),
            style: TextStyle(
              color: palette.onPanel,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('start_day_meal'),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.onPanelMuted),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final FoodItem meal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(
            context,
          ).push(buildAppPageRoute(FoodEditorPage(initialItem: meal)));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.alpha(AppColors.secondary, 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fastfood_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: TextStyle(
                            color: palette.onPanel,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.t(
                            'food_source',
                            params: {'source': l10n.sourceLabel(meal.source)},
                          ),
                          style: TextStyle(color: palette.onPanelMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${meal.calories} kcal',
                    style: TextStyle(
                      color: palette.onPanel,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MacroPill(
                    label:
                        '${context.l10n.t('protein')}: ${meal.protein.toStringAsFixed(1)} g',
                  ),
                  _MacroPill(
                    label:
                        '${context.l10n.t('carbs')}: ${meal.carbs.toStringAsFixed(1)} g',
                  ),
                  _MacroPill(
                    label:
                        '${context.l10n.t('fat')}: ${meal.fat.toStringAsFixed(1)} g',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
