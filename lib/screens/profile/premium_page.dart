import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(l10n.t('premium'))),
      body: Container(
        decoration: BoxDecoration(gradient: palette.shellGradient),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const _PremiumHero(),
              const SizedBox(height: 16),
              _PremiumFeatureCard(
                icon: Icons.psychology_alt_outlined,
                title: l10n.t('premium_feature_1_title'),
                subtitle: l10n.t('premium_feature_1_desc'),
                badge: l10n.t('feature_planned'),
              ),
              const SizedBox(height: 10),
              _PremiumFeatureCard(
                icon: Icons.auto_graph_rounded,
                title: l10n.t('premium_feature_2_title'),
                subtitle: l10n.t('premium_feature_2_desc'),
                badge: l10n.t('feature_roadmap'),
              ),
              const SizedBox(height: 10),
              _PremiumFeatureCard(
                icon: Icons.credit_card_rounded,
                title: l10n.t('premium_feature_4_title'),
                subtitle: l10n.t('premium_feature_4_desc'),
                badge: l10n.t('feature_preparation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
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
            l10n.t('premium_experience'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.onPanel,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('premium_desc'),
            style: TextStyle(color: palette.onPanelMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  const _PremiumFeatureCard({
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
              color: AppColors.alpha(AppColors.ember, 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.ember),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.onPanel,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: palette.onPanelMuted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.alpha(AppColors.secondary, 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: AppColors.ember,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
