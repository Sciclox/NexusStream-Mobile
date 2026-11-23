import 'package:flutter/material.dart';

class AppColors {
  // Paleta OLED / Cinema Midnight Pro
  static const Color background = Color(0xFF06080E);
  static const Color backgroundSecondary = Color(0xFF0B0F18);
  static const Color surface = Color(0xFF101522);
  static const Color surfaceLight = Color(0xFF171E2F);
  static const Color card = Color(0xFF121826);
  static const Color cardSelected = Color(0xFF1D263B);
  static const Color border = Color(0xFF1E283C);
  static const Color borderSubtle = Color(0xFF151C2B);
  static const Color specularBorder = Color(0x24FFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA6B2C8);
  static const Color textMuted = Color(0xFF67748B);
  
  // Acentos de alta luminancia (Cyber Cinema)
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color accentBlue = Color(0xFF2979FF);
  static const Color neonPurple = Color(0xFFB388FF);
  static const Color neonPink = Color(0xFFFF4081);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF453A);

  // Colores Glassmorphism
  static const Color glassBackground = Color(0xCC0D121D);
  static const Color glassBorder = Color(0x2600E5FF);
}

class AppTheme {
  static ThemeData darkTheme({Color accentColor = AppColors.neonCyan}) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      primaryColor: accentColor,
      splashFactory: NoSplash.splashFactory,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: accentColor.withValues(alpha: 0.2),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
      ),
    );
  }
}
