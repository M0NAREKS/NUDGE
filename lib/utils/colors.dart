import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B2248);
  static const secondary = Color(0xFFE57C33);
  static const accent = Color(0xFFB14F71);
  static const ember = Color(0xFFF0B067);
  static const info = Color(0xFF8EA8FF);
  static const background = Color(0xFFF6F0E9);
  static const surface = Color(0xFFFFFAF7);
  static const surfaceSoft = Color(0xFFF1E7DE);
  static const panel = Color(0xFF161D3D);
  static const panelElevated = Color(0xFF232A4F);
  static const panelSoft = Color(0xFF2E3561);
  static const textDark = Color(0xFF1F2340);
  static const textLight = Color(0xFF7B7380);
  static const danger = Color(0xFFD35A47);

  static const gradient = LinearGradient(
    colors: [Color(0xFF232A58), Color(0xFF5C385D), Color(0xFFE07A34)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF182046), Color(0xFF2B244F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const shellGradient = LinearGradient(
    colors: [Color(0xFF101733), Color(0xFF171D3E), Color(0xFF211C40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color alpha(Color color, double opacity) {
    return color.withAlpha((255 * opacity).round());
  }
}
