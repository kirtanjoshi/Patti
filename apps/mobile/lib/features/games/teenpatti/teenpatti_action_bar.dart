import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Action bar for Teen Patti table supporting Chaal, Raise, Pack, Side Show,
/// and Show actions with strict adherence to Rule 7 and Rule 12.
class TeenPattiActionBar extends StatelessWidget {
  final bool isMyTurn;
  final bool isSeen;
  final int currentStake;
  final int activePlayerCount;
  final bool canSideShow;
  final bool canShow;
  final bool isBlindLimitReached;
  final ValueChanged<int> onChaal;
  final VoidCallback onPack;
  final VoidCallback onSideShow;
  final VoidCallback onShow;
  final VoidCallback? onSeeCards;

  const TeenPattiActionBar({
    super.key,
    required this.isMyTurn,
    required this.isSeen,
    required this.currentStake,
    required this.activePlayerCount,
    required this.canSideShow,
    required this.canShow,
    this.isBlindLimitReached = false,
    required this.onChaal,
    required this.onPack,
    required this.onSideShow,
    required this.onShow,
    this.onSeeCards,
  });

  int get baseBet => isSeen ? currentStake * 2 : currentStake;
  int get raiseBet => isSeen ? currentStake * 4 : currentStake * 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canBet = isMyTurn && (!isBlindLimitReached || isSeen);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and info bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_outlined,
                      size: 16.0,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '${'teenpatti.stake'.tr()}: $currentStake',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSeen
                            ? colorScheme.secondaryContainer
                            : colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        isSeen ? 'teenpatti.seen'.tr() : 'teenpatti.blind'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSeen
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  isMyTurn ? 'table.your_turn'.tr() : 'table.waiting'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isMyTurn
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (isBlindLimitReached && !isSeen) ...[
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16.0,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'teenpatti.blind_limit_reached'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    if (onSeeCards != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48.0, 48.0),
                        ),
                        onPressed: onSeeCards,
                        child: Text(
                          'teenpatti.see_cards'.tr(),
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8.0),

            // Action Buttons Row
            Row(
              children: [
                // Pack Button
                Semantics(
                  button: true,
                  enabled: isMyTurn,
                  label: 'teenpatti.pack'.tr(),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(72.0, 48.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      foregroundColor: colorScheme.error,
                      side: BorderSide(
                        color: isMyTurn
                            ? colorScheme.error
                            : colorScheme.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: isMyTurn ? onPack : null,
                    child: Text(
                      'teenpatti.pack'.tr(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),

                // Side Show Button (Visible/Enabled when >2 players and previous player is seen)
                if (activePlayerCount > 2) ...[
                  Semantics(
                    button: true,
                    enabled: isMyTurn && canSideShow,
                    label: 'teenpatti.sideshow'.tr(),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(80.0, 48.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(
                          color: (isMyTurn && canSideShow)
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: (isMyTurn && canSideShow) ? onSideShow : null,
                      child: Text(
                        'teenpatti.sideshow'.tr(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                ],

                // Show Button (When 2 players remain)
                if (canShow || activePlayerCount == 2) ...[
                  Semantics(
                    button: true,
                    enabled: isMyTurn && canShow,
                    label: 'teenpatti.show'.tr(),
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(80.0, 48.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: (isMyTurn && canShow) ? onShow : null,
                      child: Text(
                        'teenpatti.show'.tr(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                ],

                // Chaal (Base Bet) Button
                Expanded(
                  child: Semantics(
                    button: true,
                    enabled: canBet,
                    label:
                        '${isSeen ? 'teenpatti.chaal'.tr() : 'teenpatti.blind'.tr()} $baseBet',
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48.0, 48.0),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: canBet ? () => onChaal(baseBet) : null,
                      child: Text(
                        '${isSeen ? 'teenpatti.chaal'.tr() : 'teenpatti.blind'.tr()} $baseBet',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),

                // Raise Button
                Semantics(
                  button: true,
                  enabled: canBet,
                  label: '${'teenpatti.raise'.tr()} $raiseBet',
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(80.0, 48.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: canBet ? () => onChaal(raiseBet) : null,
                    child: Text(
                      '${'teenpatti.raise'.tr()} $raiseBet',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
