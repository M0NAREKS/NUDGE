import 'package:flutter/material.dart';

import 'colors.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.panel,
    required this.panelElevated,
    required this.panelSoft,
    required this.textPrimary,
    required this.textMuted,
    required this.onPanel,
    required this.onPanelMuted,
    required this.border,
    required this.heroGradient,
    required this.shellGradient,
    required this.accentGradient,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceSoft;
  final Color panel;
  final Color panelElevated;
  final Color panelSoft;
  final Color textPrimary;
  final Color textMuted;
  final Color onPanel;
  final Color onPanelMuted;
  final Color border;
  final LinearGradient heroGradient;
  final LinearGradient shellGradient;
  final LinearGradient accentGradient;
  final Color shadow;

  static const light = AppPalette(
    background: Color(0xFFF7F2EC),
    surface: Color(0xFFFFFCFA),
    surfaceSoft: Color(0xFFF0E8E0),
    panel: Color(0xFFFFFFFF),
    panelElevated: Color(0xFFF6F2ED),
    panelSoft: Color(0xFFEAE4DA),
    textPrimary: Color(0xFF1F2340),
    textMuted: Color(0xFF6C6880),
    onPanel: Color(0xFF1F2340),
    onPanelMuted: Color(0xFF666178),
    border: Color(0x1A1B2248),
    heroGradient: LinearGradient(
      colors: [Color(0xFFF3E4D7), Color(0xFFF7EEE7), Color(0xFFF1E6F3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    shellGradient: LinearGradient(
      colors: [Color(0xFFF8F3EE), Color(0xFFF5F0EA), Color(0xFFF7F4F0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF243062), Color(0xFF9B4F6B), Color(0xFFE57C33)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    shadow: Color(0x140C1028),
  );

  static const dark = AppPalette(
    background: Color(0xFF101733),
    surface: Color(0xFF171E40),
    surfaceSoft: Color(0xFF222A52),
    panel: Color(0xFF161D3D),
    panelElevated: Color(0xFF232A4F),
    panelSoft: Color(0xFF2E3561),
    textPrimary: Colors.white,
    textMuted: Color(0xFFC2C3D8),
    onPanel: Colors.white,
    onPanelMuted: Color(0xFFC8CADB),
    border: Color(0x14FFFFFF),
    heroGradient: LinearGradient(
      colors: [Color(0xFF182046), Color(0xFF2B244F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    shellGradient: LinearGradient(
      colors: [Color(0xFF101733), Color(0xFF171D3E), Color(0xFF211C40)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF232A58), Color(0xFF5C385D), Color(0xFFE07A34)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    shadow: Color(0x38000000),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSoft,
    Color? panel,
    Color? panelElevated,
    Color? panelSoft,
    Color? textPrimary,
    Color? textMuted,
    Color? onPanel,
    Color? onPanelMuted,
    Color? border,
    LinearGradient? heroGradient,
    LinearGradient? shellGradient,
    LinearGradient? accentGradient,
    Color? shadow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      panel: panel ?? this.panel,
      panelElevated: panelElevated ?? this.panelElevated,
      panelSoft: panelSoft ?? this.panelSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      onPanel: onPanel ?? this.onPanel,
      onPanelMuted: onPanelMuted ?? this.onPanelMuted,
      border: border ?? this.border,
      heroGradient: heroGradient ?? this.heroGradient,
      shellGradient: shellGradient ?? this.shellGradient,
      accentGradient: accentGradient ?? this.accentGradient,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelElevated: Color.lerp(panelElevated, other.panelElevated, t)!,
      panelSoft: Color.lerp(panelSoft, other.panelSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      onPanel: Color.lerp(onPanel, other.onPanel, t)!,
      onPanelMuted: Color.lerp(onPanelMuted, other.onPanelMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
      shellGradient:
          LinearGradient.lerp(shellGradient, other.shellGradient, t)!,
      accentGradient:
          LinearGradient.lerp(accentGradient, other.accentGradient, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}

ThemeData buildAppTheme({required Brightness brightness}) {
  final palette = brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: palette.surface,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme.copyWith(
      surface: palette.surface,
      onSurface: palette.textPrimary,
    ),
    scaffoldBackgroundColor: palette.background,
    extensions: <ThemeExtension<dynamic>>[palette],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: palette.textPrimary,
      titleTextStyle: TextStyle(
        color: palette.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
    ),
    textTheme: TextTheme(
      displaySmall: TextStyle(
        color: palette.textPrimary,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        color: palette.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: palette.textPrimary, fontSize: 15),
      bodyLarge: TextStyle(
        color: palette.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: palette.textMuted,
        letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        color: palette.textMuted,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brightness == Brightness.dark
            ? palette.onPanel
            : AppColors.primary,
        backgroundColor:
            brightness == Brightness.dark ? palette.panelElevated : palette.surface,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surfaceSoft,
      selectedColor: AppColors.alpha(AppColors.secondary, 0.14),
      labelStyle: TextStyle(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: palette.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor:
          brightness == Brightness.dark ? palette.panelElevated : palette.surface,
      hintStyle: TextStyle(color: palette.textMuted),
      labelStyle: TextStyle(color: palette.textMuted),
      prefixIconColor: palette.textMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.secondary,
          width: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.secondary,
      linearTrackColor: AppColors.alpha(
        brightness == Brightness.dark ? palette.onPanel : AppColors.primary,
        0.16,
      ),
    ),
    dividerColor: palette.border,
    snackBarTheme: SnackBarThemeData(
      backgroundColor:
          brightness == Brightness.dark ? palette.panelElevated : palette.panel,
      contentTextStyle: TextStyle(color: palette.textPrimary),
    ),
  );
}
