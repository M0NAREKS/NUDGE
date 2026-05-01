import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/app_routes.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';
import '../coach/coach_chat_page.dart';
import '../food/add_food_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../workout/workout_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    this.initialTab = 0,
    this.pages,
  }) : assert(pages == null || pages.length == 5);

  final int initialTab;
  final List<Widget>? pages;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  late int _currentIndex;
  late final List<Widget Function()> _pageBuilders;
  late final List<Widget?> _cachedPages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, 4);
    _pageBuilders = <Widget Function()>[
      () => HomePage(
            embedded: true,
            onOpenFood: () => _selectTab(1),
            onOpenHydration: () => Navigator.of(context).pushNamed(
              AppRoutes.hydration,
            ),
            onOpenWorkout: () => _selectTab(2),
            onOpenCoach: () => _selectTab(3),
            onOpenProfile: () => _selectTab(4),
          ),
      () => const AddFoodPage(embedded: true),
      () => const WorkoutPage(embedded: true),
      () => const CoachChatPage(embedded: true),
      () => const ProfilePage(embedded: true),
    ];
    _cachedPages = List<Widget?>.filled(5, null);
    _ensurePageBuilt(_currentIndex);
  }

  @override
  void didUpdateWidget(covariant AppShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      final nextIndex = widget.initialTab.clamp(0, 4);
      _ensurePageBuilt(nextIndex);
      setState(() => _currentIndex = nextIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final pages = widget.pages ??
        List<Widget>.generate(
          _cachedPages.length,
          (index) => _cachedPages[index] ?? const SizedBox.shrink(),
        );

    return Scaffold(
      backgroundColor: palette.background,
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: palette.shellGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    for (final page in pages) RepaintBoundary(child: page),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: bottomInset > 0 ? bottomInset + 8 : 16,
                child: _ShellNavigationBar(
                  currentIndex: _currentIndex,
                  onSelected: _selectTab,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (!mounted || _currentIndex == index) return;
    _ensurePageBuilt(index);
    setState(() => _currentIndex = index);
  }

  void _ensurePageBuilt(int index) {
    if (widget.pages != null || _cachedPages[index] != null) return;
    _cachedPages[index] = _pageBuilders[index]();
  }
}

class _ShellNavigationBar extends StatelessWidget {
  const _ShellNavigationBar({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final capsuleBorderColor = isDark
        ? AppColors.alpha(palette.onPanel, 0.24)
        : AppColors.alpha(AppColors.primary, 0.14);
    final items = <({IconData icon, String label})>[
      (icon: Icons.home_rounded, label: l10n.t('tab_home')),
      (icon: Icons.restaurant_menu_rounded, label: l10n.t('tab_food')),
      (icon: Icons.fitness_center_rounded, label: l10n.t('tab_workout')),
      (icon: Icons.chat_bubble_rounded, label: l10n.t('tab_coach')),
      (icon: Icons.person_rounded, label: l10n.t('tab_profile')),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.alpha(palette.panel, 0.48),
                    AppColors.alpha(palette.panelElevated, 0.40),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: capsuleBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.alpha(palette.shadow, 0.24),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var index = 0; index < items.length; index++)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => onSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: currentIndex == index
                                ? AppColors.alpha(AppColors.secondary, 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                items[index].icon,
                                color: currentIndex == index
                                    ? AppColors.secondary
                                    : AppColors.alpha(palette.onPanel, 0.66),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                items[index].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: currentIndex == index
                                      ? AppColors.secondary
                                      : AppColors.alpha(palette.onPanel, 0.7),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
