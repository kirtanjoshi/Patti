import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/audio_settings_sheet.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/glass_sheet.dart';

/// Interactive Audio & Sound Design Studio for the Component Gallery.
class AudioStudioSection extends StatelessWidget {
  const AudioStudioSection({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = AudioService.instance;

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Acoustic Engine & Soundboard',
                style: PatiiTypography.body(
                  color: PatiiColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GoldButton(
                label: 'Mixer Settings',
                icon: Icons.tune,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onPressed: () => AudioSettingsSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: PatiiSpacing.s12),
          Text(
            'Cards & Felt Interaction',
            style: PatiiTypography.bodySmall
                .copyWith(color: PatiiColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GhostButton(
                label: 'Card Snap',
                icon: Icons.style,
                height: 36,
                onPressed: () => audio.playCardSnap(),
              ),
              GhostButton(
                label: 'Card Slide',
                icon: Icons.swipe,
                height: 36,
                onPressed: () => audio.playCardSlide(),
              ),
              GhostButton(
                label: 'Deal Card',
                icon: Icons.forward,
                height: 36,
                onPressed: () => audio.playDeal(),
              ),
              GhostButton(
                label: 'Riffle Shuffle',
                icon: Icons.shuffle,
                height: 36,
                onPressed: () => audio.playShuffle(),
              ),
              GhostButton(
                label: 'Fold / Muck',
                icon: Icons.close,
                height: 36,
                onPressed: () => audio.playCardFold(),
              ),
            ],
          ),
          const SizedBox(height: PatiiSpacing.s12),
          Text(
            'Chips, Pot & Economy',
            style: PatiiTypography.bodySmall
                .copyWith(color: PatiiColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GhostButton(
                label: 'Single Chip',
                icon: Icons.monetization_on,
                height: 36,
                onPressed: () => audio.playChip(),
              ),
              GhostButton(
                label: 'Raise / Multi',
                icon: Icons.layers,
                height: 36,
                onPressed: () => audio.playChipMulti(),
              ),
              GhostButton(
                label: 'Pot Rake',
                icon: Icons.move_to_inbox,
                height: 36,
                onPressed: () => audio.playPotCollect(),
              ),
              GhostButton(
                label: 'Coins Shower',
                icon: Icons.paid,
                height: 36,
                onPressed: () => audio.playCoinsCollect(),
              ),
            ],
          ),
          const SizedBox(height: PatiiSpacing.s12),
          Text(
            'Game State, Tension & Cues',
            style: PatiiTypography.bodySmall
                .copyWith(color: PatiiColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GhostButton(
                label: 'Your Turn Chime',
                icon: Icons.notifications_active,
                height: 36,
                onPressed: () => audio.playYourTurnChime(),
              ),
              GhostButton(
                label: 'Clock Tick',
                icon: Icons.timer,
                height: 36,
                onPressed: () => audio.playCountdownTick(urgent: false),
              ),
              GhostButton(
                label: 'Urgent Heartbeat',
                icon: Icons.heart_broken,
                height: 36,
                onPressed: () => audio.playCountdownTick(urgent: true),
              ),
              GhostButton(
                label: 'Special Hand Gong',
                icon: Icons.military_tech,
                height: 36,
                onPressed: () => audio.playSpecialHand(),
              ),
              GhostButton(
                label: 'Win Fanfare',
                icon: Icons.emoji_events,
                height: 36,
                onPressed: () => audio.playWinJingle(),
              ),
              GhostButton(
                label: 'Defeat Stinger',
                icon: Icons.sentiment_dissatisfied,
                height: 36,
                onPressed: () => audio.playLoseStinger(),
              ),
              GhostButton(
                label: 'Error Knock',
                icon: Icons.block,
                height: 36,
                onPressed: () => audio.playErrorBuzz(),
              ),
            ],
          ),
          const SizedBox(height: PatiiSpacing.s12),
          Text(
            'Background Music & Ambience',
            style: PatiiTypography.bodySmall
                .copyWith(color: PatiiColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GhostButton(
                label: 'Lobby Lounge BGM',
                icon: Icons.music_note,
                height: 36,
                onPressed: () => audio.playLobbyMusic(),
              ),
              GhostButton(
                label: 'Table Baize Ambient',
                icon: Icons.surround_sound,
                height: 36,
                onPressed: () => audio.playTableMusic(),
              ),
              GhostButton(
                label: 'Stop BGM',
                icon: Icons.stop,
                height: 36,
                onPressed: () => audio.stopMusic(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
