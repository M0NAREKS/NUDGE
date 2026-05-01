import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_page_route.dart';
import '../../utils/app_routes.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';
import 'profile_edit_page.dart';
import 'profile_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final user = context.watch<UserProvider>().profile;
    final embeddedBottomSpacing = embedded
        ? MediaQuery.paddingOf(context).bottom + 108.0
        : 0.0;

    if (user == null) {
      final empty = Center(child: Text(l10n.t('tab_profile')));
      return embedded ? empty : Scaffold(body: empty);
    }

    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + embeddedBottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: palette.heroGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.alpha(AppColors.secondary, 0.2),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'F',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.onPanel,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.onPanelMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final children = [
                _ManageTile(
                  icon: Icons.edit_outlined,
                  title: l10n.t('profile_edit'),
                  subtitle: l10n.t('profile_edit_subtitle'),
                  onTap: () => Navigator.of(
                    context,
                  ).push(buildAppPageRoute(const ProfileEditPage())),
                ),
                _ManageTile(
                  icon: Icons.tune_rounded,
                  title: l10n.t('settings'),
                  subtitle: l10n.t('settings_subtitle'),
                  onTap: () => Navigator.of(
                    context,
                  ).push(buildAppPageRoute(const ProfileSettingsPage())),
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    children[0],
                    const SizedBox(height: 12),
                    children[1],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: children[0]),
                  const SizedBox(width: 12),
                  Expanded(child: children[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _WideManageTile(
            icon: Icons.groups_2_outlined,
            title: l10n.t('profile_buddy'),
            subtitle: l10n.t('profile_buddy_subtitle'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.buddy),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.t('profile_future_section'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.onPanel,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _ComingSoonTile(
            icon: Icons.watch_rounded,
            title: l10n.t('future_watch_title'),
            subtitle: l10n.t('future_watch_desc'),
            badge: l10n.t('feature_soon'),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final singleColumn = constraints.maxWidth < 360;
              final cardWidth = singleColumn
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              final cards = [
                _InfoCard(
                  title: l10n.t('birth_date'),
                  value: _formatBirthDate(context, user.birthDate),
                  icon: Icons.event_outlined,
                ),
                _InfoCard(
                  title: l10n.t('age'),
                  value: user.resolvedAge?.toString() ?? '-',
                  icon: Icons.cake_outlined,
                ),
                _InfoCard(
                  title: l10n.t('height_cm'),
                  value: user.height != null ? '${user.height} cm' : '-',
                  icon: Icons.height,
                ),
                _InfoCard(
                  title: l10n.t('weight_kg'),
                  value: user.weight != null ? '${user.weight} kg' : '-',
                  icon: Icons.monitor_weight_outlined,
                ),
                _InfoCard(
                  title: l10n.t('activity_level'),
                  value: l10n.activityLabel(user.activity),
                  icon: Icons.directions_run,
                ),
              ];

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards)
                    SizedBox(width: cardWidth, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.panelElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('goals'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.onPanel,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _TargetTile(
                      label: 'BMR',
                      value: user.bmr?.toStringAsFixed(0) ?? '-',
                      icon: Icons.local_fire_department_rounded,
                    ),
                    _TargetTile(
                      label: l10n.t('daily_calories'),
                      value: user.dailyCalories?.toStringAsFixed(0) ?? '-',
                      icon: Icons.flag_circle_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await context.read<UserProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: Text(l10n.t('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (embedded) return content;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(l10n.t('tab_profile'))),
      body: SafeArea(child: content),
    );
  }
}

String _formatBirthDate(BuildContext context, DateTime? date) {
  if (date == null) {
    return '-';
  }
  return DateFormat.yMMMd(
    Localizations.localeOf(context).languageCode,
  ).format(date);
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.alpha(AppColors.info, 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.onPanel,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.onPanelMuted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.alpha(AppColors.info, 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: AppColors.info,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 126),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.panelElevated,
          borderRadius: BorderRadius.circular(18),
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
                    color: AppColors.alpha(AppColors.secondary, 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.onPanel,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.onPanelMuted, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideManageTile extends StatelessWidget {
  const _WideManageTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.alpha(AppColors.ember, 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.ember),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: palette.onPanel, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: palette.onPanelMuted, height: 1.35),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: palette.onPanelMuted,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      constraints: const BoxConstraints(minHeight: 128),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
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
                  color: AppColors.alpha(AppColors.ember, 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.ember),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.onPanelMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: palette.onPanel,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.panelSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.alpha(AppColors.secondary, 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: palette.onPanelMuted)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: palette.onPanel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
