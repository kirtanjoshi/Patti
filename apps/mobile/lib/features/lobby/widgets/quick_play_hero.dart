import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/dhaka_pattern_painter.dart';
import '../../../core/widgets/playing_card.dart';

/// Lobby hero: the one big "play now" moment. Crimson card-room panel with
/// a fanned hand on the right that settles in when the lobby opens.
class QuickPlayHero extends StatelessWidget {
  final String gameTitle;
  final String gameMeta;
  final int playingNow;
  final VoidCallback onPlay;

  const QuickPlayHero({
    super.key,
    required this.gameTitle,
    required this.gameMeta,
    required this.playingNow,
    required this.onPlay,
  });

  static const _fan = [
    engine.Card(suit: engine.Suit.D, rank: 12, deck: 0, id: 'hero-q'),
    engine.Card(suit: engine.Suit.H, rank: 13, deck: 0, id: 'hero-k'),
    engine.Card(suit: engine.Suit.S, rank: 1, deck: 0, id: 'hero-a'),
  ];

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Container(
      height: 176,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB3182F), Color(0xFF5E0B19), Color(0xFF2A0710)],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: PatiiColors.crimson.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: DhakaPatternPainter(
                  primaryColor: Colors.white.withValues(alpha: 0.05),
                  secondaryColor: Colors.transparent,
                  step: 18,
                ),
              ),
            ),
            // Fanned hand
            Positioned(
              right: -6,
              top: 18,
              bottom: -30,
              width: 150,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < 3; i++)
                    () {
                      Widget c = Transform.rotate(
                        angle: -0.32 + i * 0.26,
                        alignment: Alignment.bottomCenter,
                        child:
                            PlayingCard(card: _fan[i], width: 70, height: 100),
                      );
                      if (!reduceMotion) {
                        c = c
                            .animate()
                            .fadeIn(delay: (200 + i * 90).ms, duration: 250.ms)
                            .moveY(
                                begin: 40,
                                end: 0,
                                duration: 520.ms,
                                curve: Curves.easeOutBack);
                      }
                      return Positioned(
                          left: 14.0 + i * 28, top: i == 1 ? 0 : 8, child: c);
                    }(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 150, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'lobby.featured'.tr().toUpperCase(),
                    style: PatiiTypography.eyebrow(
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gameTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PatiiTypography.display(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15),
                  ),
                  Text(
                    gameMeta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PatiiTypography.body(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75)),
                  ),
                  const Spacer(),
                  GoldButton(
                    label: 'lobby.quick_match'.tr(),
                    icon: Icons.bolt_rounded,
                    height: 44,
                    onPressed: onPlay,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'lobby.playing_now'
                        .tr(args: [NumberFormat('#,###').format(playingNow)]),
                    style: PatiiTypography.body(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
