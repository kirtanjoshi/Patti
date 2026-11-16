import 'package:flutter/material.dart';

/// Patii Casino Design Tokens - Colors
/// Strictly defined palette according to PRD section 10 & Casino Design Spec.
abstract class PatiiColors {
  // Table Felt
  static const Color feltGreen = Color(0xFF0B5D3B);
  static const Color feltGreenDark = Color(0xFF063A25);

  // Wood Table Rail
  static const Color woodRailStart = Color(0xFF3B2314);
  static const Color woodRailEnd = Color(0xFF5A3620);
  static const Color woodRailGoldLine = Color(0xFFD4AF37);

  // Gold Accents (Coins, CTAs, Active Turn, Glows)
  static const Color gold = Color(0xFFE8B64C);
  static const Color goldLight = Color(0xFFFFD98A);
  static const Color goldDark = Color(0xFFA97A1F);

  // Nepali Crimson (Badges, Danger, Pack)
  static const Color crimson = Color(0xFFB3122E);
  static const Color crimsonLight = Color(0xFFD32F2F);

  // Navy Palette (App background, Sheets, Panels)
  static const Color navy = Color(0xFF0E1A2B);
  static const Color navySurface = Color(0xFF16253A);
  static const Color navyElevated = Color(0xFF1F3350);

  // Typography Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8C4D6);
  static const Color textMuted = Color(0xFF7F8BA0);

  // Status & Feedback
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE5484D);

  // Playing Cards
  static const Color cardFace = Color(0xFFFFFDF7);
  static const Color suitRed = Color(0xFFD0021B);
  static const Color suitBlack = Color(0xFF111111);
  static const Color cardBorder = Color(0xFFD9D5C7);
  static const Color cardCourtBg = Color(0xFFF9F5EB);

  // Casino Chips
  static const Color chipWhite = Color(0xFFF5F5F5);
  static const Color chipRed = Color(0xFFB3122E);
  static const Color chipBlue = Color(0xFF1E56A0);
  static const Color chipGreen = Color(0xFF0B5D3B);
  static const Color chipBlack = Color(0xFF222831);
  static const Color chipGold = Color(0xFFE8B64C);

  // Gradients
  static const LinearGradient goldButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldLight, gold, goldDark],
  );

  static const LinearGradient woodRailGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [woodRailStart, woodRailEnd],
  );

  static const RadialGradient feltGradient = RadialGradient(
    center: Alignment.center,
    radius: 0.95,
    colors: [feltGreen, feltGreenDark],
  );
}
