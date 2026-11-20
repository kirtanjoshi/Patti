import 'package:flutter/material.dart';

/// Patii design tokens: colours.
///
/// Direction: a dark, quiet card room. Deep ink surfaces, an emerald felt lit
/// from above, and ONE warm accent (gold) reserved for what matters right now:
/// your turn, the primary action, coins. Crimson is the Nepali identity colour
/// and the "danger / pack / fold" colour. Everything else uses white hairlines.
abstract class PatiiColors {
  // Table felt (centre -> edge of the spotlight)
  static const Color feltGreen = Color(0xFF167A57);
  static const Color feltGreenDark = Color(0xFF07301F);
  static const Color feltRim = Color(0xFF0B1A16);

  // Legacy rail tokens, kept so older call sites still compile.
  static const Color woodRailStart = Color(0xFF0B1A16);
  static const Color woodRailEnd = Color(0xFF13241F);
  static const Color woodRailGoldLine = Color(0xFF2F5C4C);

  // Accent: gold. Use for primary CTA, coins, active turn. Not for borders.
  static const Color gold = Color(0xFFF5C451);
  static const Color goldLight = Color(0xFFFFE3A3);
  static const Color goldDark = Color(0xFFB98A2C);

  // Identity + danger: Nepali crimson
  static const Color crimson = Color(0xFFD7263D);
  static const Color crimsonLight = Color(0xFFFF5468);

  // Ink surfaces (app background, sheets, panels)
  static const Color navy = Color(0xFF080D18);
  static const Color navySurface = Color(0xFF111827);
  static const Color navyElevated = Color(0xFF1A2335);

  // Hairlines and overlays: the default border language.
  static const Color hairline = Color(0x1FFFFFFF); // 12% white
  static const Color hairlineStrong = Color(0x33FFFFFF); // 20% white
  static const Color scrim = Color(0xB3060A12);

  // Text
  static const Color textPrimary = Color(0xFFF4F6FB);
  static const Color textSecondary = Color(0xFFAEB8CB);
  static const Color textMuted = Color(0xFF6F7B91);

  // Status
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFFF4D5E);
  static const Color info = Color(0xFF60A5FA);

  // Playing cards
  static const Color cardFace = Color(0xFFFCFBF7);
  static const Color suitRed = Color(0xFFD62839);
  static const Color suitBlack = Color(0xFF161A24);
  static const Color cardBorder = Color(0xFFDCD8CC);
  static const Color cardCourtBg = Color(0xFFF4EFE2);
  static const Color cardBack = Color(0xFF8E1528);
  static const Color cardBackDeep = Color(0xFF4E0A16);

  // Casino chips
  static const Color chipWhite = Color(0xFFF1F3F7);
  static const Color chipRed = Color(0xFFD7263D);
  static const Color chipBlue = Color(0xFF2563EB);
  static const Color chipGreen = Color(0xFF059669);
  static const Color chipBlack = Color(0xFF1F2937);
  static const Color chipGold = Color(0xFFF5C451);

  // Gradients
  static const LinearGradient goldButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFD978), gold, Color(0xFFE5A93A)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8455A), crimson, Color(0xFFB31B30)],
  );

  static const LinearGradient woodRailGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B302A), feltRim],
  );

  static const RadialGradient feltGradient = RadialGradient(
    center: Alignment(0, -0.25),
    radius: 1.05,
    colors: [feltGreen, Color(0xFF0E5139), feltGreenDark],
    stops: [0.0, 0.55, 1.0],
  );

  /// Lobby / app backdrop: ink with a faint crimson+blue aurora up top.
  static const LinearGradient backdrop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF111A2E), navy, navy],
    stops: [0.0, 0.45, 1.0],
  );

  /// Per-game identity accents used by lobby tiles and table titles.
  static const Map<String, Color> gameAccent = {
    'callbreak': Color(0xFF4F7CFF),
    'marriage': Color(0xFFE5484D),
    'teenpatti': Color(0xFFF5A524),
    'kitti': Color(0xFF14B8A6),
    'dhumbal': Color(0xFF8B5CF6),
    'jutpatti': Color(0xFFF97316),
    'rummy': Color(0xFF22C55E),
    'jokerrummy': Color(0xFFEC4899),
  };
}
