import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/playing_card.dart';

/// Data model representing a playable game option in the lobby.
class GameOption {
  final String id;
  final String titleKey;
  final int onlineCount;
  final String? badgeKey;
  final List<String> fannedCardSuits;
  final List<String> fannedCardRanks;
  final VoidCallback onTap;

  const GameOption({
    required this.id,
    required this.titleKey,
    required this.onlineCount,
    this.badgeKey,
    required this.fannedCardSuits,
    required this.fannedCardRanks,
    required this.onTap,
  });

  Color get accent => PatiiColors.gameAccent[id] ?? PatiiColors.gold;

  /// The tile's motif as real cards, so the lobby previews the actual deck.
  List<engine.Card> get motifCards => List.generate(3, (i) {
        final s = i < fannedCardSuits.length ? fannedCardSuits[i] : '♠';
        final r = i < fannedCardRanks.length ? fannedCardRanks[i] : 'A';
        final suit = switch (s) {
          '♥' => engine.Suit.H,
          '♦' => engine.Suit.D,
          '♣' => engine.Suit.C,
          '★' => engine.Suit.X,
          _ => engine.Suit.S,
        };
        final rank = suit == engine.Suit.X
            ? 0
            : switch (r) { 'A' => 1, 'J' => 11, 'Q' => 12, 'K' => 13, _ => int.tryParse(r) ?? 1 };
        return engine.Card(suit: suit, rank: rank, deck: 0, id: '$id-$i');
      });
}

/// Lobby game tile: per-game accent glow, a fan of real mini cards, title,
/// one-line description and live player count. Enters with a short stagger.
class GameCardTile extends StatelessWidget {
  final GameOption option;
  final int animationDelayMs;

  const GameCardTile({
    super.key,
    required this.option,
    this.animationDelayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final formattedOnline = NumberFormat('#,###').format(option.onlineCount);
    final accent = option.accent;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final cards = option.motifCards;

    Widget tile = Semantics(
      button: true,
      label: '${option.titleKey.tr()}, $formattedOnline online',
      excludeSemantics: true,
      child: Pressable(
        onPressed: option.onTap,
        pressedScale: 0.96,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: PatiiColors.navySurface,
            border: Border.all(color: PatiiColors.hairline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Accent glow from the top
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -1.1),
                        radius: 1.1,
                        colors: [accent.withValues(alpha: 0.38), accent.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: 96,
                            height: 64,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              clipBehavior: Clip.none,
                              children: [
                                for (var i = 0; i < 3; i++)
                                  Positioned(
                                    left: 12.0 + i * 22,
                                    bottom: i == 1 ? 6 : 0,
                                    child: Transform.rotate(
                                      angle: (i - 1) * 0.22,
                                      alignment: Alignment.bottomCenter,
                                      child: PlayingCard(card: cards[i], width: 38, height: 54),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              option.titleKey.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PatiiTypography.display(fontSize: 15.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (option.badgeKey != null) ...[
                            const SizedBox(width: 6),
                            _Badge(text: option.badgeKey!.tr(), hot: option.badgeKey == 'lobby.hot'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'lobby.meta.${option.id}'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PatiiTypography.body(fontSize: 12, color: PatiiColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: PatiiColors.success,
                              boxShadow: [
                                BoxShadow(color: PatiiColors.success.withValues(alpha: 0.6), blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'lobby.online_count'.tr(args: [formattedOnline]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PatiiTypography.body(fontSize: 11.5, color: PatiiColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!reduceMotion) {
      tile = tile
          .animate()
          .fadeIn(delay: Duration(milliseconds: 120 + animationDelayMs), duration: 320.ms)
          .moveY(begin: 18, end: 0, duration: 420.ms, curve: Curves.easeOutCubic);
    }
    return tile;
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool hot;

  const _Badge({required this.text, required this.hot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: hot ? PatiiColors.crimson : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: PatiiTypography.eyebrow(fontSize: 8, color: Colors.white)),
    );
  }
}
