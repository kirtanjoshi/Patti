import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Patii Casino Typography using GoogleFonts (Cinzel, Poppins, Mukta)
abstract class PatiiTypography {
  // Display font for Casino Titles, Pots, Big Numbers
  static TextStyle cinzel({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color color = PatiiColors.textPrimary,
    double? letterSpacing,
  }) {
    return GoogleFonts.cinzel(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Body and UI font
  static TextStyle poppins({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = PatiiColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Devanagari / Nepali text font
  static TextStyle mukta({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = PatiiColors.textPrimary,
    double? letterSpacing,
  }) {
    return GoogleFonts.mukta(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle caption({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w400,
    bool bold = false,
    Color color = PatiiColors.textMuted,
  }) {
    return poppins(
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.w700 : fontWeight,
      color: color,
    );
  }

  // Pre-configured text styles
  static final TextStyle potDisplay = cinzel(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: PatiiColors.goldLight,
    letterSpacing: 1.2,
  );

  static final TextStyle titleLarge = cinzel(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: PatiiColors.textPrimary,
    letterSpacing: 0.8,
  );

  static final TextStyle titleMedium = cinzel(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: PatiiColors.goldLight,
  );

  static final TextStyle bodyLarge = poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: PatiiColors.textPrimary,
  );

  static final TextStyle bodyMedium = poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: PatiiColors.textSecondary,
  );

  static final TextStyle bodySmall = poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: PatiiColors.textMuted,
  );

  static final TextStyle buttonLabel = poppins(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: PatiiColors.navy,
    letterSpacing: 0.5,
  );

  static final TextStyle cardRank = poppins(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: PatiiColors.suitBlack,
  );
}
