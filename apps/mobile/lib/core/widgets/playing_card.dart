import 'dart:math' as math;
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart' as engine;
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'dhaka_pattern_painter.dart';
import 'suit_icon.dart';

enum CardSizeVariant {
  hand, // 64 x 90
  table, // 52 x 74
  mini, // 40 x 56
}

/// Patii playing card.
///
/// Readability first: a large corner index (rank over suit) is what players
/// actually scan in an overlapping fan, so it gets the most weight. Pips are
/// vector shapes, court cards get a tinted frame with a large letter.
class PlayingCard extends StatelessWidget {
  final engine.Card card;
  final bool isFaceDown;
  final bool isSelected;
  final bool isPlayable;
  final String? badgeText;
  final double? width;
  final double? height;
  final CardSizeVariant sizeVariant;
  final VoidCallback? onTap;

  const PlayingCard({
    super.key,
    required this.card,
    this.isFaceDown = false,
    this.isSelected = false,
    this.isPlayable = true,
    this.badgeText,
    this.width,
    this.height,
    this.sizeVariant = CardSizeVariant.hand,
    this.onTap,
  });

  const PlayingCard.table({
    super.key,
    required this.card,
    this.isFaceDown = false,
    this.isSelected = false,
    this.isPlayable = true,
    this.badgeText,
    this.width,
    this.height,
    this.onTap,
  }) : sizeVariant = CardSizeVariant.table;

  double get resolvedWidth =>
      width ??
      switch (sizeVariant) {
        CardSizeVariant.hand => 64.0,
        CardSizeVariant.table => 52.0,
        CardSizeVariant.mini => 40.0,
      };

  double get resolvedHeight =>
      height ??
      switch (sizeVariant) {
        CardSizeVariant.hand => 90.0,
        CardSizeVariant.table => 74.0,
        CardSizeVariant.mini => 56.0,
      };

  bool get isJoker => card.rank == 0 || card.suit == engine.Suit.X;

  bool get isRed => card.suit == engine.Suit.H || card.suit == engine.Suit.D;

  Color get suitColor => isJoker
      ? PatiiColors.crimson
      : (isRed ? PatiiColors.suitRed : PatiiColors.suitBlack);

  String get rankLabel => switch (card.rank) {
        0 => 'JOKER',
        1 || 14 => 'A', // some engines use 14 for a high ace
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        _ => '${card.rank}',
      };

  String get suitSymbol => switch (card.suit) {
        engine.Suit.S => '♠',
        engine.Suit.H => '♥',
        engine.Suit.D => '♦',
        engine.Suit.C => '♣',
        engine.Suit.X => '★',
      };

  bool get isCourtCard => card.rank >= 11 && card.rank <= 13;

  bool get isAce => card.rank == 1 || card.rank == 14;

  String get _suitName => switch (card.suit) {
        engine.Suit.S => 'Spades',
        engine.Suit.H => 'Hearts',
        engine.Suit.D => 'Diamonds',
        engine.Suit.C => 'Clubs',
        engine.Suit.X => 'Joker',
      };

  /// Asset path for high-resolution realistic card graphics.
  String get assetPath {
    final effectiveRank = switch (card.rank) {
      0 => 0,
      14 => 1,
      _ => card.rank,
    };
    final suitCode = switch (card.suit) {
      engine.Suit.S => 'S',
      engine.Suit.H => 'H',
      engine.Suit.D => 'D',
      engine.Suit.C => 'C',
      engine.Suit.X => 'X',
    };
    if (isJoker || suitCode == 'X') {
      return 'assets/images/cards/0X.png';
    }
    return 'assets/images/cards/$effectiveRank$suitCode.png';
  }

  /// Default back design asset path.
  static const String backAssetPath = 'assets/images/cards/card_back.png';

  @override
  Widget build(BuildContext context) {
    final w = resolvedWidth;
    final h = resolvedHeight;
    final radius = BorderRadius.circular((w * 0.11).clamp(4.0, 9.0));
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final semanticsLabel = isFaceDown
        ? 'Face-down card'
        : isJoker
            ? 'Joker${badgeText != null ? ', $badgeText' : ''}'
            : '$rankLabel of $_suitName${badgeText != null ? ', $badgeText' : ''}';

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      selected: isSelected,
      child: GestureDetector(
        onTap: isPlayable ? onTap : null,
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          transform:
              Matrix4.translationValues(0, isSelected ? -h * 0.2 : 0.0, 0),
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              if (isSelected) ...[
                // Deep physical elevation shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  spreadRadius: 1,
                ),
                // Warm card-lift edge reflection (restrained luxury)
                BoxShadow(
                  color: PatiiColors.goldLight.withValues(alpha: 0.38),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ] else ...[
                // Micro contact shadow at card base
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 1.5,
                  offset: const Offset(0, 0.8),
                ),
                // Mid-distance card body drop
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 5,
                  offset: const Offset(0, 2.5),
                ),
                // Ambient soft felt bleed
                BoxShadow(
                  color: const Color(0xFF040A07).withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                Positioned.fill(
                  child: isFaceDown
                      ? _CardBack(width: w)
                      : _buildFace(w, h, radius),
                ),
                if (!isPlayable && !isFaceDown)
                  Positioned.fill(
                    child: ColoredBox(
                        color: const Color(0xFF0A1020).withValues(alpha: 0.42)),
                  ),
                if (isSelected)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(color: PatiiColors.gold, width: 1.5),
                      ),
                    ),
                  ),
                if (badgeText != null)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: _Badge(text: badgeText!, cardWidth: w),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFace(double w, double h, BorderRadius radius) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFD6D1C4), width: 0.7),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildFallbackFace(w, h, radius),
          Image.asset(
            assetPath,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
          // Subtle physical cardstock sheen
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: const Alignment(-0.8, -1.0),
                    end: const Alignment(0.8, 1.0),
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.03),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackFace(double w, double h, BorderRadius radius) {
    final idx = (w * 0.27).clamp(10.0, 19.0);
    final idxSuit = (w * 0.19).clamp(7.0, 13.0);
    final pad = (w * 0.07).clamp(2.5, 5.0);
    final showMirror = h >= 64;

    Widget index() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isJoker ? '★' : rankLabel,
              style: PatiiTypography.display(
                fontSize: rankLabel.length > 1 && !isJoker ? idx * 0.88 : idx,
                fontWeight: FontWeight.w800,
                color: suitColor,
                height: 1.0,
                letterSpacing: rankLabel.length > 1 ? -1.0 : 0,
              ),
            ),
            SizedBox(height: idx * 0.08),
            if (!isJoker)
              SuitIcon(suit: card.suit, size: idxSuit, color: suitColor),
          ],
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PatiiColors.cardFace, Color(0xFFF2EFE6)],
        ),
        borderRadius: radius,
        border: Border.all(color: PatiiColors.cardBorder, width: 0.8),
      ),
      child: Stack(
        children: [
          Positioned(top: pad, left: pad, child: index()),
          if (showMirror)
            Positioned(
              bottom: pad,
              right: pad,
              child: Transform.rotate(angle: math.pi, child: index()),
            ),
          Positioned.fill(
            left: w * 0.24,
            right: w * 0.12,
            top: h * 0.2,
            bottom: h * 0.12,
            child: Center(child: _centerArt(w, h)),
          ),
        ],
      ),
    );
  }

  Widget _centerArt(double w, double h) {
    if (isJoker) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SuitIcon(
              suit: engine.Suit.X, size: w * 0.4, color: PatiiColors.crimson),
          if (h >= 64)
            Text(
              'JOKER',
              style: PatiiTypography.display(
                fontSize: (w * 0.13).clamp(6.0, 10.0),
                fontWeight: FontWeight.w800,
                color: PatiiColors.suitBlack,
                letterSpacing: 1,
              ),
            ),
        ],
      );
    }
    if (isCourtCard) {
      return Container(
        width: w * 0.56,
        height: h * 0.6,
        decoration: BoxDecoration(
          color: suitColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(w * 0.06),
          border:
              Border.all(color: suitColor.withValues(alpha: 0.28), width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              rankLabel,
              style: PatiiTypography.display(
                fontSize: w * 0.36,
                fontWeight: FontWeight.w800,
                color: suitColor,
                height: 1.0,
              ),
            ),
            SizedBox(height: h * 0.03),
            SuitIcon(suit: card.suit, size: w * 0.16, color: suitColor),
          ],
        ),
      );
    }
    return SuitIcon(
      suit: card.suit,
      size: w * (isAce ? 0.5 : 0.38),
      color: suitColor,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double cardWidth;

  const _Badge({required this.text, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: PatiiColors.crimson,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 3),
        ],
      ),
      child: Text(
        text,
        style: PatiiTypography.display(
          fontSize: (cardWidth * 0.12).clamp(6.5, 8.5),
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Crimson card back: classic authentic back with Nepali Dhaka lattice fallback.
class _CardBack extends StatelessWidget {
  final double width;

  const _CardBack({required this.width});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildFallbackBack(context),
        Image.asset(
          PlayingCard.backAssetPath,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFallbackBack(BuildContext context) {
    final inset = (width * 0.07).clamp(2.0, 4.0);
    final medallion = width * 0.42;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: [PatiiColors.cardBack, PatiiColors.cardBackDeep],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width * 0.07),
            border: Border.all(
                color: PatiiColors.goldLight.withValues(alpha: 0.45),
                width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(width * 0.07),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: DhakaPatternPainter(
                      primaryColor:
                          PatiiColors.goldLight.withValues(alpha: 0.16),
                      secondaryColor:
                          PatiiColors.goldLight.withValues(alpha: 0.10),
                      step: (width * 0.16).clamp(6.0, 11.0),
                    ),
                  ),
                ),
                if (width >= 30)
                  Container(
                    width: medallion,
                    height: medallion,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PatiiColors.cardBackDeep,
                      border: Border.all(
                          color: PatiiColors.goldLight.withValues(alpha: 0.7),
                          width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'प',
                      style: PatiiTypography.body(
                        fontSize: medallion * 0.56,
                        fontWeight: FontWeight.w700,
                        color: PatiiColors.goldLight,
                        height: 1.1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
