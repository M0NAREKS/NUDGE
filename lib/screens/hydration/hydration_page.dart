import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/hydration_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/models/daily_hydration_summary.dart';
import '../../services/models/hydration_entry.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';

class HydrationPage extends StatelessWidget {
  const HydrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final user = context.watch<UserProvider>().profile;
    final hydrationProvider = context.watch<HydrationProvider>();

    if (user == null) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(title: Text(l10n.t('hydration_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(l10n.t('hydration_title'))),
      body: Container(
        decoration: BoxDecoration(gradient: palette.shellGradient),
        child: SafeArea(
          top: false,
          child: StreamBuilder<DailyHydrationSummary>(
            stream: hydrationProvider.summaryForToday(
              user.uid,
              profile: user,
            ),
            builder: (context, summarySnapshot) {
              final summary =
                  summarySnapshot.data ??
                  DailyHydrationSummary(
                    goalMl: hydrationProvider.recommendedGoalMl(user),
                    updatedAt: DateTime.now(),
                  );
              return StreamBuilder<List<HydrationEntry>>(
                stream: hydrationProvider.entriesForToday(user.uid),
                builder: (context, entrySnapshot) {
                  final entries = entrySnapshot.data ?? const <HydrationEntry>[];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _HydrationHero(
                        summary: summary,
                        userName: user.name,
                      ),
                      const SizedBox(height: 16),
                      _GoalPanel(
                        summary: summary,
                        onGoalSelected: (goalMl) async {
                          await context.read<HydrationProvider>().updateGoal(
                                userProvider: context.read<UserProvider>(),
                                goalMl: goalMl,
                              );
                        },
                      ),
                      const SizedBox(height: 16),
                      _QuickAddPanel(
                        saving: hydrationProvider.isSaving,
                        onAdd: (amountMl, label) async {
                          try {
                            await context.read<HydrationProvider>().addQuickEntry(
                                  userProvider: context.read<UserProvider>(),
                                  amountMl: amountMl,
                                  label: label,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.t(
                                    'hydration_added',
                                    params: {
                                      'amount': _formatLiters(amountMl),
                                    },
                                  ),
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$error')),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _EntriesPanel(
                        entries: entries,
                        onDelete: (entry) async {
                          await context.read<HydrationProvider>().deleteEntry(
                                userProvider: context.read<UserProvider>(),
                                entryId: entry.id,
                              );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static String _formatLiters(int amountMl) {
    if (amountMl % 1000 == 0) {
      return '${amountMl ~/ 1000} L';
    }
    return '${(amountMl / 1000).toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')} L';
  }
}

class _HydrationHero extends StatelessWidget {
  const _HydrationHero({
    required this.summary,
    required this.userName,
  });

  final DailyHydrationSummary summary;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final consumedLiters = (summary.totalMl / 1000).toStringAsFixed(2);
    final goalLiters = (summary.goalMl / 1000).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('hydration_daily_title'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.onPanelMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t(
              'hydration_greeting',
              params: {'name': userName.split(' ').first},
            ),
            style: TextStyle(
              color: palette.onPanel,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('hydration_summary'),
            style: TextStyle(
              color: palette.onPanelMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: l10n.t('hydration_consumed'),
                  value: '$consumedLiters L',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: l10n.t('hydration_goal'),
                  value: '$goalLiters L',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: l10n.t('remaining'),
                  value:
                      '${(summary.remainingMl / 1000).toStringAsFixed(2)} L',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: summary.progress,
              minHeight: 12,
              backgroundColor: AppColors.alpha(palette.onPanel, 0.12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t(
              'hydration_progress',
              params: {'percent': (summary.progress * 100).round().toString()},
            ),
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

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alpha(palette.onPanel, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.alpha(palette.onPanel, 0.08)),
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
    );
  }
}

class _GoalPanel extends StatelessWidget {
  const _GoalPanel({
    required this.summary,
    required this.onGoalSelected,
  });

  final DailyHydrationSummary summary;
  final ValueChanged<int> onGoalSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    const options = [2000, 2500, 3000, 3500];

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
          Text(
            l10n.t('hydration_goal_panel'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.onPanel,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('hydration_goal_desc'),
            style: TextStyle(color: palette.onPanelMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text('${(option / 1000).toStringAsFixed(1)} L'),
                  selected: summary.goalMl == option,
                  onSelected: (_) => onGoalSelected(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAddPanel extends StatelessWidget {
  const _QuickAddPanel({
    required this.saving,
    required this.onAdd,
  });

  final bool saving;
  final Future<void> Function(int amountMl, String label) onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final presets = <({int amount, IconData icon, String title, String subtitle})>[
      (
        amount: 250,
        icon: Icons.local_cafe_rounded,
        title: l10n.t('hydration_glass'),
        subtitle: '250 ml',
      ),
      (
        amount: 500,
        icon: Icons.water_drop_rounded,
        title: l10n.t('hydration_bottle_small'),
        subtitle: '0.5 L',
      ),
      (
        amount: 750,
        icon: Icons.sports_bar_rounded,
        title: l10n.t('hydration_sports_bottle'),
        subtitle: '0.75 L',
      ),
      (
        amount: 1000,
        icon: Icons.opacity_rounded,
        title: l10n.t('hydration_bottle_large'),
        subtitle: '1.0 L',
      ),
    ];

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
          Text(
            l10n.t('hydration_quick_add'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.onPanel,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('hydration_quick_add_desc'),
            style: TextStyle(color: palette.onPanelMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: presets.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) {
              final preset = presets[index];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: saving ? null : () => onAdd(preset.amount, preset.title),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.panelSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.alpha(AppColors.info, 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(preset.icon, color: AppColors.info),
                      ),
                      const Spacer(),
                      Text(
                        preset.title,
                        style: TextStyle(
                          color: palette.onPanel,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.subtitle,
                        style: TextStyle(
                          color: palette.onPanelMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EntriesPanel extends StatelessWidget {
  const _EntriesPanel({
    required this.entries,
    required this.onDelete,
  });

  final List<HydrationEntry> entries;
  final Future<void> Function(HydrationEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

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
          Text(
            l10n.t('hydration_recent_entries'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.onPanel,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              l10n.t('hydration_no_entries'),
              style: TextStyle(color: palette.onPanelMuted, height: 1.35),
            )
          else
            ...[
              for (final entry in entries) ...[
                _EntryRow(entry: entry, onDelete: () => onDelete(entry)),
                if (entry != entries.last) const SizedBox(height: 10),
              ],
            ],
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.onDelete,
  });

  final HydrationEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final liters = (entry.amountMl / 1000).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.alpha(AppColors.secondary, 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: TextStyle(
                    color: palette.onPanel,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text('$liters L', style: TextStyle(color: palette.onPanelMuted)),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.t('delete'),
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppColors.alpha(palette.onPanelMuted, 0.84),
            ),
          ),
        ],
      ),
    );
  }
}
