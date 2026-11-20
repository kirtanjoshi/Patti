import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/playing_card.dart';

/// Data class representing a played card in a Callbreak trick.
class PlayedTrickCard {
  final int seat;
  final engine.Card card;

  const PlayedTrickCard({
    required this.seat,
    required this.card,
  });
}

/// Callbreak centre trick area.
///
/// Each card flies in from the direction of the player who played it and
/// rests slightly toward them. When [winningSeat] is set, the whole trick
/// sweeps toward the winner and fades, so the result is felt, not just read.
class CallbreakTrickArea extends StatelessWidget {
  final List<PlayedTrickCard> playedCards;
  final String phase;
  final int currentTurnSeat;
  final int? winningSeat;

  const CallbreakTrickArea({
    super.key,
    required this.playedCards,
    required this.phase,
    required this.currentTurnSeat,
    this.winningSeat,
  });

  /// Unit direction from the table centre toward each seat.
  static Offset _dir(int seat) => switch (seat) {
        0 => const Offset(0, 1),
        1 => const Offset(-1, 0),
        2 => const Offset(0, -1),
        3 => const Offset(1, 0),
        _ => Offset.zero,
      };

  static Offset _rest(int seat) => Offset(_dir(seat).dx * 34, _dir(seat).dy * 22);

  static double _tilt(int seat) => switch (seat) {
        1 => -0.10,
        2 => 0.05,
        3 => 0.10,
        _ => -0.03,
      };

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final hint = phase == 'bidding'
        ? 'callbreak.bid'.tr()
        : currentTurnSeat == 0
            ? 'table.your_turn'.tr()
            : 'table.waiting'.tr();

    return SizedBox(
      width: 200,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // During bidding the bid panel already says what to do.
          if (playedCards.isEmpty && phase != 'bidding')
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                hint,
                key: ValueKey(hint),
                style: PatiiTypography.eyebrow(
                  fontSize: 11,
                  color: currentTurnSeat == 0 && phase != 'bidding'
                      ? PatiiColors.goldLight
                      : Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: winningSeat == null ? 0 : 1),
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 520),
            curve: Curves.easeInCubic,
            builder: (context, t, _) {
              final sweep = winningSeat == null ? Offset.zero : _dir(winningSeat!) * 170 * t;
              return Opacity(
                opacity: (1 - t * 0.9).clamp(0.0, 1.0),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: playedCards.map((played) {
                    Widget card = PlayingCard.table(card: played.card, width: 50, height: 70);
                    if (!reduceMotion) {
                      final from = _dir(played.seat) * 140;
                      card = card
                          .animate(key: ValueKey(played.card.id))
                          .move(begin: from, end: Offset.zero, duration: 280.ms, curve: Curves.easeOutCubic)
                          // rotate() is in turns: ~15-20 degrees of spin-in.
                          .rotate(begin: _tilt(played.seat) * 0.5, end: 0, duration: 280.ms)
                          .fadeIn(duration: 120.ms);
                    }
                    return Transform.translate(
                      key: ValueKey(played.card.id),
                      offset: Offset.lerp(_rest(played.seat), sweep, t)!,
                      child: Transform.scale(
                        scale: 1 - 0.4 * t,
                        child: Transform.rotate(angle: _tilt(played.seat), child: card),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
