import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Dark glass bottom navigation bar with gold active indicator line.
class LobbyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const LobbyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (Icons.casino_outlined, Icons.casino, 'lobby.nav_home'),
      (Icons.people_alt_outlined, Icons.people_alt, 'lobby.nav_friends'),
      (Icons.emoji_events_outlined, Icons.emoji_events, 'lobby.nav_leaderboard'),
      (Icons.person_outline, Icons.person, 'lobby.nav_profile'),
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: PatiiColors.navySurface.withValues(alpha: 0.90),
            border: Border(
              top: BorderSide(
                color: PatiiColors.gold.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: List.generate(navItems.length, (index) {
                  final (iconInactive, iconActive, labelKey) = navItems[index];
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: labelKey.tr(),
                      child: InkWell(
                        onTap: () => onTabSelected(index),
                        splashColor: PatiiColors.gold.withValues(alpha: 0.15),
                        highlightColor: Colors.transparent,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Gold indicator line at top of selected tab
                            if (isSelected)
                              Positioned(
                                top: 0,
                                child: Container(
                                  width: 38,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: PatiiColors.gold,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: PatiiColors.goldLight,
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Icon + Label
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected ? iconActive : iconInactive,
                                  size: 22,
                                  color: isSelected
                                      ? PatiiColors.goldLight
                                      : PatiiColors.textMuted,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  labelKey.tr(),
                                  style: PatiiTypography.poppins(
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? PatiiColors.goldLight
                                        : PatiiColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
