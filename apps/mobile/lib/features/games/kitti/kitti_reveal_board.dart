import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:patii_engine/patii_engine.dart';
import '../../table/widgets/playing_card_widget.dart';
import 'kitti_models.dart';

class KittiRevealBoard extends StatefulWidget {
  final List<KittiPlayer> players;
  final KittiRoundSummary summary;
  final VoidCallback onNextDeal;

  const KittiRevealBoard({
    super.key,
    required this.players,
    required this.summary,
    required this.onNextDeal,
  });

  @override
  State<KittiRevealBoard> createState() => _KittiRevealBoardState();
}

class _KittiRevealBoardState extends State<KittiRevealBoard> {
  int _activeShowIndex = 0; // 0, 1, 2 for Show 1, 2, 3

  String _showLabel(int index) {
    switch (index) {
      case 0:
        return 'kitti.show_1'.tr();
      case 1:
        return 'kitti.show_2'.tr();
      case 2:
      default:
        return 'kitti.show_3'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showResult = widget.summary.showResults.length > _activeShowIndex
        ? widget.summary.showResults[_activeShowIndex]
        : null;

    final winnerSeat = showResult?.winnerSeat;
    final winningPlayer = winnerSeat != null
        ? widget.players.firstWhere((p) => p.seatIndex == winnerSeat)
        : null;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Salami or Kitti Carryover Banner
          if (widget.summary.isSalami)
            _buildCelebrationBanner(
              colorScheme: colorScheme,
              theme: theme,
              icon: Icons.auto_awesome,
              title: 'kitti.salami_bonus'.tr(),
              subtitle: 'kitti.salami_desc'.tr(),
            )
          else if (widget.summary.isKittiCarryover)
            _buildCelebrationBanner(
              colorScheme: colorScheme,
              theme: theme,
              icon: Icons.sync,
              title: 'kitti.kitti_carryover'.tr(),
              subtitle: 'kitti.kitti_desc'.tr(),
            ),

          const SizedBox(height: 8.0),

          // Show selector tabs (1st Show, 2nd Show, 3rd Show)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isSelected = _activeShowIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Semantics(
                  button: true,
                  label: _showLabel(index),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: ChoiceChip(
                      label: Text(_showLabel(index)),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _activeShowIndex = index);
                      },
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 8.0),

          // Show Outcome Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showResult?.isVoid == true ? Icons.handshake : Icons.emoji_events,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8.0),
                Text(
                  showResult?.isVoid == true
                      ? 'kitti.show_void'.tr()
                      : (winningPlayer != null
                          ? 'kitti.show_winner'.tr(args: [winningPlayer.displayName])
                          : ''),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8.0),

          // Player Shows Grid for the active show
          ...widget.players.where((p) => !p.isFolded).map((player) {
            final isThisWinner = winnerSeat == player.seatIndex;
            final evaluation = showResult?.handEvaluations[player.seatIndex];
            final handCards = player.arrangedHands != null &&
                    player.arrangedHands!.length > _activeShowIndex
                ? player.arrangedHands![_activeShowIndex]
                : <Card>[];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isThisWinner
                      ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isThisWinner ? colorScheme.primary : colorScheme.outlineVariant,
                    width: isThisWinner ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Player info column
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                player.displayName,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (isThisWinner) ...[
                                const SizedBox(width: 4.0),
                                Icon(Icons.star, size: 14, color: colorScheme.primary),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          if (evaluation != null)
                            Text(
                              evaluation.labelKey.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isThisWinner ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                fontWeight: isThisWinner ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          const SizedBox(height: 2.0),
                          Text(
                            'kitti.shows_won'.tr(args: [player.showWins.toString()]),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cards row
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: handCards.map((card) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: PlayingCardWidget(
                              card: card,
                              width: 44.0,
                              height: 64.0,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16.0),

          // Next Deal Button
          Semantics(
            button: true,
            label: 'kitti.next_deal'.tr(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48.0),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: widget.onNextDeal,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  'kitti.next_deal'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationBanner({
    required ColorScheme colorScheme,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onPrimaryContainer, size: 28),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
