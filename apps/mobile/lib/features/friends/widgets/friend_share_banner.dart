import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/api_const.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';

/// Hero Banner for sharing the user's friend invite link.
class FriendShareBanner extends StatelessWidget {
  final String friendCode;

  const FriendShareBanner({super.key, required this.friendCode});

  void _shareInviteLink(String friendCode) {
    HapticFeedback.lightImpact();
    final link = ApiConst.friendInviteUrl(friendCode);
    Share.share(
      'friends.share_text'.tr(args: [link, friendCode]),
      subject: 'Join me on Patii Card Games!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B1D38), Color(0xFF161C2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PatiiColors.gold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: PatiiColors.crimson.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PatiiColors.gold.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_rounded,
                    color: PatiiColors.gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'friends.share_link_title'.tr(),
                      style: PatiiTypography.display(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'friends.share_link_subtitle'.tr(),
                      style: PatiiTypography.body(
                        fontSize: 12,
                        color: PatiiColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GoldButton(
            label: 'friends.share_link_button'.tr(),
            icon: Icons.link_rounded,
            height: 44,
            onPressed: () => _shareInviteLink(friendCode),
          ),
        ],
      ),
    );
  }
}
