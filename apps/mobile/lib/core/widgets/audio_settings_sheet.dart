import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'buttons.dart';
import 'glass_sheet.dart';

/// Modal sheet for audio mixing & haptic preferences.
class AudioSettingsSheet extends StatelessWidget {
  const AudioSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AudioSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioService.instance;

    return GlassSheet(
      title: 'Audio & Haptics',
      child: ListenableBuilder(
        listenable: audio,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Sound Effects (SFX) ---
                _buildToggleRow(
                  icon: Icons.volume_up_rounded,
                  title: 'Sound Effects (SFX)',
                  value: audio.soundEnabled,
                  onChanged: (val) => audio.setSoundEnabled(val),
                ),
                if (audio.soundEnabled)
                  _buildSlider(
                    value: audio.sfxVolume,
                    onChanged: (val) => audio.setSfxVolume(val),
                  ),
                const SizedBox(height: 12),

                // --- Background Music (BGM) ---
                _buildToggleRow(
                  icon: Icons.music_note_rounded,
                  title: 'Background Music (BGM)',
                  value: audio.musicEnabled,
                  onChanged: (val) => audio.setMusicEnabled(val),
                ),
                if (audio.musicEnabled)
                  _buildSlider(
                    value: audio.musicVolume,
                    onChanged: (val) => audio.setMusicVolume(val),
                  ),
                const SizedBox(height: 12),

                // --- Haptic Feedback ---
                _buildToggleRow(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic Feedback',
                  value: audio.vibrationEnabled,
                  onChanged: (val) => audio.setVibrationEnabled(val),
                ),
                const SizedBox(height: 18),

                // --- Sound Studio Preview ---
                Text(
                  'AUDIO PREVIEW',
                  style: PatiiTypography.bodySmall.copyWith(
                    color: PatiiColors.goldLight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PreviewButton(
                      label: 'Card Snap',
                      icon: Icons.style_rounded,
                      onPressed: () => audio.playCardSnap(),
                    ),
                    _PreviewButton(
                      label: 'Chips Clink',
                      icon: Icons.monetization_on_rounded,
                      onPressed: () => audio.playChip(multi: true),
                    ),
                    _PreviewButton(
                      label: 'Turn Chime',
                      icon: Icons.notifications_active_rounded,
                      onPressed: () => audio.playYourTurnChime(),
                    ),
                    _PreviewButton(
                      label: 'Win Fanfare',
                      icon: Icons.emoji_events_rounded,
                      onPressed: () => audio.playWinJingle(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: PatiiColors.goldLight, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: PatiiTypography.body(
              color: PatiiColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: value,
          activeColor: PatiiColors.gold,
          activeTrackColor: PatiiColors.goldDark,
          inactiveThumbColor: PatiiColors.textMuted,
          inactiveTrackColor: PatiiColors.hairline,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSlider({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 8),
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: PatiiColors.gold,
                inactiveTrackColor: PatiiColors.hairline,
                thumbColor: PatiiColors.goldLight,
                overlayColor: PatiiColors.gold.withValues(alpha: 0.2),
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: PatiiTypography.bodySmall.copyWith(
              color: PatiiColors.textSecondary,
              fontFamily: 'Mukta',
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PreviewButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: PatiiColors.navy.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PatiiColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: PatiiColors.goldLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: PatiiTypography.bodySmall.copyWith(
                color: PatiiColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
