import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Patii App Theme
abstract class PatiiTheme {
  static ThemeData get casinoDarkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: PatiiColors.gold,
      onPrimary: PatiiColors.navy,
      primaryContainer: PatiiColors.goldDark,
      onPrimaryContainer: PatiiColors.textPrimary,
      secondary: PatiiColors.crimson,
      onSecondary: PatiiColors.textPrimary,
      secondaryContainer: PatiiColors.crimsonLight,
      surface: PatiiColors.navySurface,
      onSurface: PatiiColors.textPrimary,
      error: PatiiColors.danger,
      onError: PatiiColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: PatiiColors.navy,
      canvasColor: PatiiColors.navySurface,
      cardColor: PatiiColors.navySurface,
      dividerColor: Colors.white.withValues(alpha: 0.1),
      textTheme: TextTheme(
        displayLarge: PatiiTypography.cinzel(fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: PatiiTypography.cinzel(fontSize: 26, fontWeight: FontWeight.bold),
        displaySmall: PatiiTypography.cinzel(fontSize: 20, fontWeight: FontWeight.bold),
        headlineMedium: PatiiTypography.titleLarge,
        titleLarge: PatiiTypography.titleMedium,
        titleMedium: PatiiTypography.bodyLarge,
        bodyLarge: PatiiTypography.bodyLarge,
        bodyMedium: PatiiTypography.bodyMedium,
        bodySmall: PatiiTypography.bodySmall,
        labelLarge: PatiiTypography.buttonLabel,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: PatiiColors.navy,
        foregroundColor: PatiiColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: PatiiTypography.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: PatiiColors.navySurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: PatiiSpacing.rounded12,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PatiiColors.navySurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: PatiiSpacing.rounded16,
          side: const BorderSide(
            color: PatiiColors.goldDark,
            width: 1,
          ),
        ),
      ),
    );
  }
}
