import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/models/notification_preferences.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final settings = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(l10n.t('settings_title'))),
      body: Container(
        decoration: BoxDecoration(gradient: palette.shellGradient),
        child: SafeArea(
          top: false,
          child: settings.isLoaded
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _HeroPanel(
                      title: l10n.t('app_settings_title'),
                      subtitle: l10n.t('app_settings_desc'),
                    ),
                    const SizedBox(height: 16),
                    _PanelTitle(title: l10n.t('theme_section')),
                    const SizedBox(height: 10),
                    _SelectionPanel(
                      child: _ThemeModeSelector(
                        value: settings.themeMode,
                        onChanged: settings.setThemeMode,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PanelTitle(title: l10n.t('language_section')),
                    const SizedBox(height: 10),
                    _SelectionPanel(
                      child: _LanguageSelector(
                        value: settings.localeCode,
                        onChanged: settings.setLocaleCode,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PanelTitle(title: l10n.t('coach_section')),
                    const SizedBox(height: 10),
                    _SelectionPanel(
                      child: _CoachModeSelector(
                        value: settings.coachMode,
                        onChanged: settings.setCoachMode,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PanelTitle(title: l10n.t('notifications_section')),
                    const SizedBox(height: 10),
                    _NotificationPanel(
                      onPermissionDenied: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.t('notifications_denied')),
                          ),
                        );
                      },
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.onPanel,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: palette.onPanelMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Text(
      title,
      style: TextStyle(
        color: palette.onPanelMuted,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = <ThemeMode, String>{
      ThemeMode.system: l10n.t('theme_system'),
      ThemeMode.light: l10n.t('theme_light'),
      ThemeMode.dark: l10n.t('theme_dark'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('theme_mode'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.entries.map((entry) {
            return _ChoiceTile(
              label: entry.value,
              selected: entry.key == value,
              onTap: () => onChanged(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('language_title'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ChoiceTile(
              label: l10n.t('language_turkish'),
              selected: value == 'tr',
              onTap: () => onChanged('tr'),
            ),
            _ChoiceTile(
              label: l10n.t('language_english'),
              selected: value == 'en',
              onTap: () => onChanged('en'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CoachModeSelector extends StatelessWidget {
  const _CoachModeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const modes = ['hardcore coach', 'friendly coach', 'balanced coach'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('coach_mode'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.t('coach_mode_desc'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.palette.onPanelMuted),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: modes.map((mode) {
            return _ChoiceTile(
              label: l10n.coachModeLabel(mode),
              subtitle: l10n.coachModeDescription(mode),
              selected: value == mode,
              onTap: () => onChanged(mode),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({required this.onPermissionDenied});

  final VoidCallback onPermissionDenied;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<AppSettingsProvider>();
    final preferences = settings.notificationPreferences;
    final palette = context.palette;

    Future<void> updatePreferences(NotificationPreferences next) async {
      final saved = await context
          .read<AppSettingsProvider>()
          .setNotificationPreferences(next);
      if (!saved && context.mounted) {
        onPermissionDenied();
      }
    }

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
            l10n.t('notifications_title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('notifications_master'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.onPanelMuted),
          ),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.secondary,
            title: Text(l10n.t('notifications_enable')),
            subtitle: Text(l10n.t('notifications_enable_desc')),
            value: preferences.enabled,
            onChanged: (value) {
              updatePreferences(preferences.copyWith(enabled: value));
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.secondary,
            title: Text(l10n.t('notifications_meal')),
            value: preferences.mealReminders,
            onChanged: preferences.enabled
                ? (value) => updatePreferences(
                    preferences.copyWith(mealReminders: value),
                  )
                : null,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.secondary,
            title: Text(l10n.t('notifications_workout')),
            value: preferences.workoutReminders,
            onChanged: preferences.enabled
                ? (value) => updatePreferences(
                    preferences.copyWith(workoutReminders: value),
                  )
                : null,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.secondary,
            title: Text(l10n.t('notifications_checkin')),
            value: preferences.dailyCheckIn,
            onChanged: preferences.enabled
                ? (value) => updatePreferences(
                    preferences.copyWith(dailyCheckIn: value),
                  )
                : null,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.secondary,
            title: Text(l10n.t('notifications_smart_nudges')),
            subtitle: Text(l10n.t('notifications_smart_nudges_desc')),
            value: preferences.smartNudges,
            onChanged: preferences.enabled
                ? (value) => updatePreferences(
                    preferences.copyWith(smartNudges: value),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: preferences.enabled
                  ? () async {
                      final sent = await context
                          .read<AppSettingsProvider>()
                          .showTestNotification();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            sent
                                ? l10n.t('notifications_test_sent')
                                : l10n.t('notifications_test_disabled'),
                          ),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(l10n.t('notifications_test_button')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: subtitle == null ? 120 : 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.alpha(AppColors.secondary, 0.18)
              : palette.panelSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.alpha(AppColors.secondary, 0.32)
                : palette.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.tune_rounded,
              color: selected ? AppColors.secondary : palette.onPanelMuted,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: palette.onPanel,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: palette.onPanelMuted, height: 1.25),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
