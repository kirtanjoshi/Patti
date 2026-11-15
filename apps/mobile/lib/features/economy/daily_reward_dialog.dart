import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DailyRewardDialog extends StatelessWidget {
  const DailyRewardDialog({super.key});

  static const List<int> dailyRewards = [500, 750, 1000, 1250, 1500, 2000, 3000];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const currentStreakDay = 3; // e.g. Day 3

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0), // 8-pt grid
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'economy.daily_reward'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              '${'economy.streak'.tr()}: $currentStreakDay ${'economy.day'.tr()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),

            // 7-Day Streak Grid
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: List.generate(7, (index) {
                final day = index + 1;
                final reward = dailyRewards[index];
                final isClaimed = day < currentStreakDay;
                final isToday = day == currentStreakDay;

                return Container(
                  width: 64.0,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isToday
                        ? colorScheme.primaryContainer
                        : isClaimed
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.surface,
                    border: Border.all(
                      color: isToday ? colorScheme.primary : colorScheme.outlineVariant,
                      width: isToday ? 2.0 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${'economy.day'.tr()} $day',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '$reward',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isToday ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Icon(
                        isClaimed
                            ? Icons.check_circle
                            : isToday
                                ? Icons.stars
                                : Icons.lock,
                        size: 16.0,
                        color: isToday ? colorScheme.primary : colorScheme.outline,
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 24.0),
            Semantics(
              button: true,
              label: 'economy.claim'.tr(),
              child: SizedBox(
                height: 48.0, // min 48px tap target
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('economy.claim'.tr()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
