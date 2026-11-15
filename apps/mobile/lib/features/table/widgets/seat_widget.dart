import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SeatWidget extends StatelessWidget {
  final String displayName;
  final int? bid;
  final int tricksWon;
  final bool isCurrentTurn;
  final bool isBot;
  final bool isConnected;

  const SeatWidget({
    super.key,
    required this.displayName,
    this.bid,
    this.tricksWon = 0,
    this.isCurrentTurn = false,
    this.isBot = false,
    this.isConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '$displayName, ${callbreakLabel()}',
      child: Container(
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isCurrentTurn ? colorScheme.primary : colorScheme.outlineVariant,
            width: isCurrentTurn ? 2.5 : 1.0,
          ),
        ),
        constraints: const BoxConstraints(minWidth: 100, minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.secondary,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isBot) ...[
                      const SizedBox(width: 4.0),
                      Icon(Icons.smart_toy, size: 14, color: colorScheme.outline),
                    ],
                  ],
                ),
                Text(
                  callbreakLabel(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String callbreakLabel() {
    final bidText = bid != null ? '$bid' : '-';
    return '${'callbreak.bids'.tr()}: $bidText | ${'callbreak.tricks'.tr()}: $tricksWon';
  }
}
