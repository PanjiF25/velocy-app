import 'package:flutter/material.dart';

class AppTheme {
  // Common Colors
  static const Color primaryLight = Color(0xFF0F6E56);
  static const Color primaryDark = Color(0xFF10B981);
  
  static const Color primaryContainerLight = Color(0xFFC4EED0);
  static const Color primaryContainerDark = Color(0xFF005440);
  
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color errorDark = Color(0xFFFFB4AB);

  static const Color warningLight = Color(0xFF9E6C00);
  static const Color warningDark = Color(0xFFE2C44B);

  static const Color infoLight = Color(0xFF0061A4);
  static const Color infoDark = Color(0xFF3B82F6);

  // Backgrounds & Surfaces
  static const Color bgLight = Color(0xFFF9F9FF);
  static const Color bgDark = Color(0xFF131313);

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color surfaceVariantLight = Color(0xFFE9EDFF);
  static const Color surfaceVariantDark = Color(0xFF2E2E2E); // Adjusted for glass panels

  // Typography
  static const Color textMainLight = Color(0xFF141B2B);
  static const Color textMainDark = Color(0xFFE5E2E1);

  static const Color textMutedLight = Color(0xFF3F4944);
  static const Color textMutedDark = Color(0xFFBBCABF);

  // Outlines
  static const Color outlineLight = Color(0xFFBEC9C3);
  static const Color outlineDark = Color(0xFF4B4B4B);

  // Helper Methods
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color primary(BuildContext context) => isDark(context) ? primaryDark : primaryLight;
  static Color primaryContainer(BuildContext context) => isDark(context) ? primaryContainerDark : primaryContainerLight;
  static Color error(BuildContext context) => isDark(context) ? errorDark : errorLight;
  static Color warning(BuildContext context) => isDark(context) ? warningDark : warningLight;
  static Color info(BuildContext context) => isDark(context) ? infoDark : infoLight;
  
  static Color bg(BuildContext context) => isDark(context) ? bgDark : bgLight;
  static Color surface(BuildContext context) => isDark(context) ? surfaceDark : surfaceLight;
  static Color surfaceVariant(BuildContext context) => isDark(context) ? surfaceVariantDark : surfaceVariantLight;
  
  static Color textMain(BuildContext context) => isDark(context) ? textMainDark : textMainLight;
  static Color textMuted(BuildContext context) => isDark(context) ? textMutedDark : textMutedLight;
  
  static Color outline(BuildContext context) => isDark(context) ? outlineDark : outlineLight;
}
