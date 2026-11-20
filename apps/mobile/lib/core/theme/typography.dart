import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Patii typography.
///
/// - display(): Sora. Titles, numbers, coins, pot, scores. Tabular figures so
///   counters don't jitter while animating.
/// - body(): Mukta. UI text in both Latin and Devanagari (PRD 10.4).
/// Both families ship in assets/fonts, so nothing is fetched at runtime.
abstract class PatiiTypography {
  static List<String> _devanagariFallback(FontWeight w) =>
      [GoogleFonts.mukta(fontWeight: w).fontFamily!];

  static TextStyle display({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color color = PatiiColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.sora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? (fontSize >= 18 ? -0.3 : 0),
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    ).copyWith(fontFamilyFallback: _devanagariFallback(fontWeight));
  }

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = PatiiColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.mukta(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height ?? 1.25,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle mukta({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = PatiiColors.textPrimary,
    double? letterSpacing,
  }) =>
      body(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// Small uppercase-ish label: section eyebrows, chip labels.
  static TextStyle eyebrow({
    double fontSize = 10.5,
    Color color = PatiiColors.textMuted,
  }) =>
      display(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.2,
      );

  static TextStyle caption({
    double fontSize = 11.5,
    FontWeight fontWeight = FontWeight.w400,
    bool bold = false,
    Color color = PatiiColors.textMuted,
  }) {
    return body(
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.w700 : fontWeight,
      color: color,
    );
  }

  static final TextStyle potDisplay = display(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: PatiiColors.goldLight,
  );

  static final TextStyle titleLarge = display(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle titleMedium = display(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle bodyLarge = body(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle bodyMedium = body(
    fontSize: 14,
    color: PatiiColors.textSecondary,
  );

  static final TextStyle bodySmall = body(
    fontSize: 12.5,
    color: PatiiColors.textMuted,
  );

  static final TextStyle buttonLabel = display(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF241A05),
  );

  static final TextStyle cardRank = display(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: PatiiColors.suitBlack,
  );
}
