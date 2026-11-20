import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Patii App Theme
abstract class PatiiTheme {
  static ThemeData get casinoDarkTheme {
    const colorScheme = ColorScheme.dark(
      primary: PatiiColors.gold,
      onPrimary: Color(0xFF241A05),
      primaryContainer: PatiiColors.goldDark,
      onPrimaryContainer: PatiiColors.textPrimary,
      secondary: PatiiColors.crimson,
      onSecondary: PatiiColors.textPrimary,
      secondaryContainer: PatiiColors.crimsonLight,
      surface: PatiiColors.navySurface,
      onSurface: PatiiColors.textPrimary,
      error: PatiiColors.danger,
      onError: PatiiColors.textPrimary,
      outline: PatiiColors.hairlineStrong,
      outlineVariant: PatiiColors.hairline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: PatiiColors.navy,
      canvasColor: PatiiColors.navySurface,
      cardColor: PatiiColors.navySurface,
      dividerColor: PatiiColors.hairline,
      splashFactory: InkSparkle.splashFactory,
      // Fade-through between lobby (portrait) and tables (landscape) hides
      // the orientation flip instead of sliding a half-rotated page.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: TextTheme(
        displayLarge: PatiiTypography.display(fontSize: 32, fontWeight: FontWeight.w800),
        displayMedium: PatiiTypography.display(fontSize: 26, fontWeight: FontWeight.w800),
        displaySmall: PatiiTypography.display(fontSize: 20, fontWeight: FontWeight.w700),
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
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: PatiiTypography.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: PatiiColors.navySurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: PatiiSpacing.rounded16,
          side: const BorderSide(color: PatiiColors.hairline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PatiiColors.navyElevated,
        elevation: 6,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: PatiiSpacing.rounded20,
          side: const BorderSide(color: PatiiColors.hairline),
        ),
        titleTextStyle: PatiiTypography.titleMedium,
        contentTextStyle: PatiiTypography.bodyMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PatiiColors.gold,
          foregroundColor: const Color(0xFF241A05),
          elevation: 0,
          minimumSize: const Size(88, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: PatiiSpacing.rounded12),
          textStyle: PatiiTypography.buttonLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PatiiColors.textSecondary,
          minimumSize: const Size(64, 44),
          textStyle: PatiiTypography.body(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PatiiColors.gold,
          foregroundColor: const Color(0xFF241A05),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(borderRadius: PatiiSpacing.rounded12),
          textStyle: PatiiTypography.buttonLabel,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: PatiiColors.textPrimary,
        unselectedLabelColor: PatiiColors.textMuted,
        labelStyle: PatiiTypography.display(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: PatiiTypography.display(fontSize: 14, fontWeight: FontWeight.w600),
        dividerColor: PatiiColors.hairline,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: PatiiColors.gold, width: 3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          foregroundColor: PatiiColors.textSecondary,
          selectedBackgroundColor: PatiiColors.gold,
          selectedForegroundColor: const Color(0xFF241A05),
          side: const BorderSide(color: PatiiColors.hairlineStrong),
          textStyle: PatiiTypography.display(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        labelStyle: PatiiTypography.body(fontSize: 14, color: PatiiColors.textSecondary),
        hintStyle: PatiiTypography.body(fontSize: 14, color: PatiiColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: PatiiSpacing.rounded12,
          borderSide: const BorderSide(color: PatiiColors.hairlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PatiiSpacing.rounded12,
          borderSide: const BorderSide(color: PatiiColors.hairlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PatiiSpacing.rounded12,
          borderSide: const BorderSide(color: PatiiColors.gold, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PatiiColors.navyElevated,
        contentTextStyle: PatiiTypography.body(fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: PatiiSpacing.rounded12),
      ),
    );
  }
}
