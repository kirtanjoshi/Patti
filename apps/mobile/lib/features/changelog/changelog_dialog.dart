import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';

/// Modal dialog displaying in-app release notes and changelog
class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showDialog(
      context: context,
      barrierColor: PatiiColors.scrim,
      builder: (ctx) => const ChangelogDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        decoration: BoxDecoration(
          color: PatiiColors.navyElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PatiiColors.gold.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: PatiiColors.hairline)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PatiiColors.gold.withValues(alpha: 0.16),
                    ),
                    child: const Icon(Icons.auto_awesome, color: PatiiColors.gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What's New in Patii",
                          style: PatiiTypography.display(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: PatiiColors.goldLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: PatiiColors.gold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v1.1.0',
                                style: PatiiTypography.body(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: PatiiColors.navy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nov 20, 2026',
                              style: PatiiTypography.body(fontSize: 11, color: PatiiColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: PatiiColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _buildSectionHeader('Current Release (v1.1.0)'),
                  const SizedBox(height: 10),
                  _buildFeatureItem(
                    icon: Icons.radar_rounded,
                    iconColor: PatiiColors.gold,
                    title: 'Players Around Me (Nearby Radar)',
                    description:
                        'Discover active card game lovers in your neighborhood (~500m to 10km) with privacy-safe coarse location. Send instant friend requests & table invites.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.account_circle_rounded,
                    iconColor: PatiiColors.info,
                    title: 'Guest Login & 1-Tap Google Upgrade',
                    description:
                        'Play instantly as a Guest with 10,000 bonus coins. Link your Google account anytime without losing any coins, friends, or stats.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.link_rounded,
                    iconColor: PatiiColors.chipBlue,
                    title: 'Viral Deep Linking & Invite Links',
                    description:
                        'Share room and friend invite links directly via WhatsApp, Viber, or Messenger (patii://room/... & https://patii.app/r/...).',
                  ),
                  _buildFeatureItem(
                    icon: Icons.people_alt_rounded,
                    iconColor: PatiiColors.success,
                    title: 'Real-Time Friends & Direct Table Invites',
                    description:
                        'See live online status of your friends and invite them into your room with a single tap.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.casino_rounded,
                    iconColor: PatiiColors.crimson,
                    title: 'Multiplayer Private Rooms',
                    description:
                        'Create custom private rooms for all 8 card games with 6-character room codes, bot seats, and customizable house rules.',
                  ),

                  const SizedBox(height: 16),
                  _buildSectionHeader('Previous Release (v1.0.0)'),
                  const SizedBox(height: 10),
                  _buildFeatureItem(
                    icon: Icons.style_rounded,
                    iconColor: PatiiColors.textSecondary,
                    title: '8 Classic Nepali Card Games',
                    description:
                        'Callbreak, Marriage, Teen Patti, Kitti, Dhumbal, Jutpatti, Nepali Rummy, and Joker Rummy.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.smart_toy_rounded,
                    iconColor: PatiiColors.textSecondary,
                    title: 'Offline Mode & Smart ISMCTS Bots',
                    description:
                        'Play offline anywhere with full local rules parity and tree-search AI bots.',
                  ),
                  _buildFeatureItem(
                    icon: Icons.palette_rounded,
                    iconColor: PatiiColors.textSecondary,
                    title: 'Casino Visual Redesign',
                    description:
                        'Traditional Dhaka card backs, felt tables, realistic animations, audio chimes, and haptics.',
                  ),
                ],
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: Pressable(
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: PatiiColors.goldButtonGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: PatiiColors.gold.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Awesome, Got It!',
                      style: PatiiTypography.display(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: PatiiTypography.display(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: PatiiColors.goldLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PatiiTypography.display(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: PatiiColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: PatiiTypography.body(
                    fontSize: 11.5,
                    color: PatiiColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
