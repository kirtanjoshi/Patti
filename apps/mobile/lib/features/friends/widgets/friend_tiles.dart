import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Tile displaying an incoming pending friend request.
class PendingFriendRequestTile extends StatelessWidget {
  final FriendModel request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const PendingFriendRequestTile({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PatiiColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatiiColors.hairline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: PatiiColors.gold.withValues(alpha: 0.15),
            child: Text(
              request.displayName.isNotEmpty ? request.displayName[0] : '?',
              style: const TextStyle(
                  color: PatiiColors.goldLight, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.displayName,
                  style: PatiiTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PatiiColors.textPrimary,
                  ),
                ),
                Text(
                  request.friendCode,
                  style: PatiiTypography.body(
                      fontSize: 11, color: PatiiColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_rounded,
                color: PatiiColors.success, size: 28),
            onPressed: onAccept,
            tooltip: 'friends.accept'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined,
                color: PatiiColors.textMuted, size: 28),
            onPressed: onDecline,
            tooltip: 'friends.decline'.tr(),
          ),
        ],
      ),
    );
  }
}

/// Tile displaying an accepted friend (online or offline).
class FriendItemTile extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback onInvite;

  const FriendItemTile({
    super.key,
    required this.friend,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PatiiColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatiiColors.hairline),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: PatiiColors.navyElevated,
                child: Text(
                  friend.displayName.isNotEmpty ? friend.displayName[0] : '?',
                  style: const TextStyle(
                      color: PatiiColors.textPrimary,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (friend.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: PatiiColors.success,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: PatiiColors.navySurface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PatiiTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PatiiColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  friend.currentGame != null
                      ? 'friends.status_in_game'.tr(args: [friend.currentGame!])
                      : friend.isOnline
                          ? 'friends.status_online'.tr()
                          : 'friends.status_offline'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PatiiTypography.body(
                    fontSize: 11.5,
                    color: friend.isOnline
                        ? PatiiColors.success
                        : PatiiColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onInvite,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (friend.isOnline ? PatiiColors.info : PatiiColors.gold)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (friend.isOnline ? PatiiColors.info : PatiiColors.gold)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'Invite to Room',
                style: TextStyle(
                  color:
                      friend.isOnline ? PatiiColors.info : PatiiColors.goldLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
