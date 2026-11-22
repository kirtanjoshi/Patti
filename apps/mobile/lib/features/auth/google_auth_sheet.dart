import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/toast_banner.dart';
import '../changelog/changelog_dialog.dart';

class GoogleAuthSheet extends ConsumerWidget {
  const GoogleAuthSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const GoogleAuthSheet(),
    );
  }

  void _copyFriendCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ToastBanner.show(
      context,
      'auth.code_copied'.tr(),
      icon: Icons.copy_rounded,
    );
  }

  void _shareFriendCode(String code) {
    Share.share(
      'friends.share_text'.tr(args: ['https://patii.app/f/$code', code]),
      subject: 'Patii Card Games Friend Invite',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user == null) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: PatiiColors.navyElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: PatiiColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // User Avatar & Name
          CircleAvatar(
            radius: 36,
            backgroundColor: PatiiColors.gold.withValues(alpha: 0.2),
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : 'P',
              style: PatiiTypography.display(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: PatiiColors.goldLight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName,
            style: PatiiTypography.display(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: PatiiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: user.isGuest
                  ? Colors.amber.withValues(alpha: 0.15)
                  : PatiiColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: user.isGuest ? Colors.amber : PatiiColors.success,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isGuest ? Icons.person_outline : Icons.verified_user,
                  size: 13,
                  color: user.isGuest ? Colors.amber : PatiiColors.success,
                ),
                const SizedBox(width: 5),
                Text(
                  user.isGuest
                      ? 'auth.guest_badge'.tr()
                      : 'auth.google_verified'.tr(),
                  style: PatiiTypography.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.isGuest ? Colors.amber : PatiiColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Friend Code Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: PatiiColors.navySurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PatiiColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'auth.my_friend_code'.tr(),
                        style: PatiiTypography.body(
                          fontSize: 11.5,
                          color: PatiiColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.friendCode,
                        style: PatiiTypography.display(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: PatiiColors.goldLight,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      color: PatiiColors.gold, size: 20),
                  onPressed: () => _copyFriendCode(context, user.friendCode),
                  tooltip: 'Copy',
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded,
                      color: PatiiColors.info, size: 20),
                  onPressed: () => _shareFriendCode(user.friendCode),
                  tooltip: 'Share',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Link Google Account banner if guest
          if (user.isGuest) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PatiiColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: PatiiColors.info.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined,
                          color: PatiiColors.info, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'auth.link_google'.tr(),
                          style: PatiiTypography.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PatiiColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'auth.link_google_desc'.tr(),
                    style: PatiiTypography.body(
                      fontSize: 12,
                      color: PatiiColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GoldButton(
                    label: 'auth.link_google'.tr(),
                    icon: Icons.g_mobiledata_rounded,
                    height: 42,
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await ref
                          .read(authProvider.notifier)
                          .linkGoogleWithPrompt();
                      if (context.mounted && success) {
                        ToastBanner.show(
                          context,
                          'Account successfully linked with Google!',
                          icon: Icons.check_circle_rounded,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // What's New / Changelog Button
          Pressable(
            onPressed: () {
              Navigator.pop(context);
              ChangelogDialog.show(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: PatiiColors.navySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PatiiColors.hairline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PatiiColors.gold.withValues(alpha: 0.16),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: PatiiColors.gold, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's New (v1.1.0)",
                          style: PatiiTypography.display(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: PatiiColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Nearby Radar, Deep Links & Friends',
                          style: PatiiTypography.body(
                              fontSize: 11, color: PatiiColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: PatiiColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sign Out Action
          SizedBox(
            width: double.infinity,
            child: GhostButton(
              label: 'auth.sign_out'.tr(),
              icon: Icons.logout_rounded,
              height: 44,
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}
