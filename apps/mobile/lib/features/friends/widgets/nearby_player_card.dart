import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';

/// Card widget representing a discovered player in the Nearby Radar list.
/// Shows player name, level, distance, playing status, Wi-Fi badge,
/// and quick actions for friend requests and table invites.
class NearbyPlayerCard extends StatelessWidget {
  final NearbyPlayerModel player;
  final bool isSelected;
  final VoidCallback onAddFriend;
  final VoidCallback onInvite;

  const NearbyPlayerCard({
    super.key,
    required this.player,
    this.isSelected = false,
    required this.onAddFriend,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? PatiiColors.navyElevated : PatiiColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? PatiiColors.gold : PatiiColors.hairline,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: PatiiColors.gold.withValues(alpha: 0.2),
            child: Text(
              player.displayName.isNotEmpty
                  ? player.displayName[0].toUpperCase()
                  : '?',
              style: PatiiTypography.display(
                  fontSize: 15, color: PatiiColors.goldLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.displayName,
                        style: PatiiTypography.body(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: PatiiColors.navyElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lv ${player.level}',
                        style: PatiiTypography.body(
                            fontSize: 9, color: PatiiColors.gold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        color: PatiiColors.gold, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      player.distanceText,
                      style: PatiiTypography.body(
                          fontSize: 11, color: PatiiColors.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: PatiiColors.hairline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        player.currentGame != null
                            ? 'Playing ${player.currentGame}'
                            : 'In Lobby',
                        style: PatiiTypography.body(
                          fontSize: 11,
                          color: player.currentGame != null
                              ? const Color(0xFF00E5FF)
                              : PatiiColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (player.isSameWifi) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E676).withValues(alpha: 0.22),
                          PatiiColors.gold.withValues(alpha: 0.18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00E676).withValues(alpha: 0.8),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📶', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 5),
                        Text(
                          'Same Wi-Fi Network',
                          style: PatiiTypography.body(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00E676),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              SizedBox(
                height: 28,
                child: Pressable(
                  onPressed: onAddFriend,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: PatiiColors.goldButtonGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+ Friend',
                      style: PatiiTypography.body(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 24,
                child: Pressable(
                  onPressed: onInvite,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PatiiColors.navyElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: PatiiColors.hairline),
                    ),
                    child: Text(
                      'Invite',
                      style: PatiiTypography.body(
                          fontSize: 9.5, color: PatiiColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
