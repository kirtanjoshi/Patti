import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';

/// Floating glass navigation bar. The active tab gets a sliding capsule.
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
    const navItems = [
      (Icons.style_outlined, Icons.style, 'lobby.nav_home'),
      (Icons.people_alt_outlined, Icons.people_alt, 'lobby.nav_friends'),
      (Icons.emoji_events_outlined, Icons.emoji_events, 'lobby.nav_leaderboard'),
      (Icons.person_outline, Icons.person, 'lobby.nav_profile'),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 64,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: PatiiColors.navyElevated.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PatiiColors.hairline),
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  final itemW = c.maxWidth / navItems.length;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        left: itemW * currentIndex,
                        top: 0,
                        bottom: 0,
                        width: itemW,
                        child: Container(
                          decoration: BoxDecoration(
                            color: PatiiColors.gold.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(navItems.length, (index) {
                          final (iconInactive, iconActive, labelKey) = navItems[index];
                          final isSelected = index == currentIndex;
                          final color = isSelected ? PatiiColors.goldLight : PatiiColors.textMuted;
                          return Expanded(
                            child: Semantics(
                              button: true,
                              selected: isSelected,
                              label: labelKey.tr(),
                              excludeSemantics: true,
                              child: Pressable(
                                onPressed: () => onTabSelected(index),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: isSelected ? 1.08 : 1.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(isSelected ? iconActive : iconInactive, size: 22, color: color),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      labelKey.tr(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PatiiTypography.body(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: color,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
