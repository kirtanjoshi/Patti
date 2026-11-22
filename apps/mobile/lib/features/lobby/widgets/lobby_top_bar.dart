import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/audio_settings_sheet.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/coin_counter.dart';

/// Lobby header: avatar with a level-progress ring, name + level,
/// coin balance with a "+" and a utility button.
class LobbyTopBar extends StatelessWidget {
  final int coins;
  final int vipLevel;
  final String username;
  final VoidCallback onAddCoins;
  final VoidCallback onOpenGallery;
  final VoidCallback? onAvatarTap;
  final double levelProgress;

  const LobbyTopBar({
    super.key,
    required this.coins,
    this.vipLevel = 3,
    this.username = 'Player 1',
    required this.onAddCoins,
    required this.onOpenGallery,
    this.onAvatarTap,
    this.levelProgress = 0.62,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          Pressable(
            onPressed: onAvatarTap,
            child: Semantics(
              label: '$username, ${'lobby.level'.tr()} $vipLevel',
              child: SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: levelProgress,
                        strokeWidth: 2.5,
                        strokeCap: StrokeCap.round,
                        color: PatiiColors.gold,
                        backgroundColor: PatiiColors.hairline,
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE5484D), Color(0xFF7A1220)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        username.isNotEmpty
                            ? username.characters.first.toUpperCase()
                            : 'P',
                        style: PatiiTypography.display(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PatiiTypography.display(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  'lobby.level_short'.tr(args: ['$vipLevel']),
                  style: PatiiTypography.body(
                      fontSize: 12, color: PatiiColors.textSecondary),
                ),
              ],
            ),
          ),
          CoinCounter(
              coins: coins, showPlusButton: true, onPlusTap: onAddCoins),
          Semantics(
            button: true,
            label: 'Audio Settings',
            child: Pressable(
              onPressed: () => AudioSettingsSheet.show(context),
              child: const SizedBox(
                width: 40,
                height: 48,
                child: Icon(Icons.volume_up_rounded,
                    color: PatiiColors.textSecondary, size: 21),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'lobby.dev_gallery'.tr(),
            child: Pressable(
              onPressed: onOpenGallery,
              child: const SizedBox(
                width: 44,
                height: 48,
                child: Icon(Icons.tune_rounded,
                    color: PatiiColors.textSecondary, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
