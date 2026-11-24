import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';

/// Card widget representing a discovered player in the Nearby Radar list.
/// Clearly distinguishes between:
/// - Nearby device (not connected -> Connect via Shake)
/// - Connected device (via Shake -> explicit Add Friend)
/// - Pending friend request (outgoing -> Request Sent, incoming -> Accept/Decline)
/// - Existing friend (Friend badge -> Invite to Room)
class NearbyPlayerCard extends StatelessWidget {
  final NearbyPlayerModel player;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback? onConnect;
  final VoidCallback onAddFriend;
  final VoidCallback? onAcceptRequest;
  final VoidCallback? onDeclineRequest;
  final VoidCallback onInvite;

  const NearbyPlayerCard({
    super.key,
    required this.player,
    this.isSelected = false,
    this.isBusy = false,
    this.onConnect,
    required this.onAddFriend,
    this.onAcceptRequest,
    this.onDeclineRequest,
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
          color: isSelected
              ? PatiiColors.gold
              : player.isConnected
                  ? const Color(0xFF00E676).withValues(alpha: 0.5)
                  : PatiiColors.hairline,
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
                            : player.isOnline
                                ? 'Online'
                                : 'Offline',
                        style: PatiiTypography.body(
                          fontSize: 11,
                          color: player.currentGame != null
                              ? const Color(0xFF00E5FF)
                              : player.isOnline
                                  ? PatiiColors.success
                                  : PatiiColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (player.isSameWifi)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF00E676).withValues(alpha: 0.7),
                          ),
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
                    if (player.isConnected && !player.isFriend)
                      _StatusBadge(
                        label: 'Connected',
                        color: const Color(0xFF00E5FF),
                        icon: Icons.link_rounded,
                      ),
                    if (player.isFriend)
                      _StatusBadge(
                        label: 'Friend',
                        color: PatiiColors.gold,
                        icon: Icons.people_alt_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildActionColumn(),
        ],
      ),
    );
  }

  Widget _buildActionColumn() {
    if (isBusy) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: PatiiColors.gold,
        ),
      );
    }

    // 1. Already friends -> Invite to Room (never show Add Friend)
    if (player.isFriend ||
        player.friendStatus == NearbyFriendStatus.accepted) {
      return SizedBox(
        height: 30,
        child: Pressable(
          onPressed: onInvite,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PatiiColors.info.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: PatiiColors.info.withValues(alpha: 0.5)),
            ),
            child: Text(
              'Invite to Room',
              style: PatiiTypography.body(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: PatiiColors.info,
              ),
            ),
          ),
        ),
      );
    }

    // 2. Incoming friend request -> Accept / Decline
    if (player.friendStatus == NearbyFriendStatus.incomingPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle_rounded,
                color: PatiiColors.success, size: 26),
            onPressed: onAcceptRequest ?? () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Accept',
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.cancel_outlined,
                color: PatiiColors.textMuted, size: 26),
            onPressed: onDeclineRequest ?? () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Reject',
          ),
        ],
      );
    }

    // 3. Outgoing friend request -> Pending pill
    if (player.friendStatus == NearbyFriendStatus.outgoingPending ||
        player.hasPendingRequest) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: PatiiColors.navyElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PatiiColors.hairline),
        ),
        child: Text(
          'Pending',
          style: PatiiTypography.body(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: PatiiColors.goldLight,
          ),
        ),
      );
    }

    // 4. Connected device (via Shake) -> Explicit Add Friend
    if (player.isConnected) {
      return SizedBox(
        height: 30,
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
              'Add Friend',
              style: PatiiTypography.body(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: PatiiColors.navy,
              ),
            ),
          ),
        ),
      );
    }

    // 5. Nearby device (not connected yet) -> Shake to Connect
    return SizedBox(
      height: 30,
      child: Pressable(
        onPressed: onConnect ?? onAddFriend,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PatiiColors.gold.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: PatiiColors.gold.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.vibration_rounded,
                  size: 13, color: PatiiColors.goldLight),
              const SizedBox(width: 4),
              Text(
                'Connect',
                style: PatiiTypography.body(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: PatiiColors.goldLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: PatiiTypography.body(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
