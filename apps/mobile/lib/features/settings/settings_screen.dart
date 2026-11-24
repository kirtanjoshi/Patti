import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_const.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/toast_banner.dart';
import '../changelog/changelog_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String _kRadarDiscoverable = 'patii_radar_discoverable';
  bool _radarDiscoverable = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _radarDiscoverable = prefs.getBool(_kRadarDiscoverable) ?? true;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleRadarVisibility(bool value) async {
    setState(() => _radarDiscoverable = value);
    HapticFeedback.selectionClick();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRadarDiscoverable, value);
    } catch (_) {}

    final token = ref.read(authProvider).token;
    if (token != null) {
      try {
        await http
            .post(
              Uri.parse(ApiConst.nearbyVisibility),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'isVisible': value}),
            )
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    if (mounted) {
      ToastBanner.show(
        context,
        value
            ? 'Radar visibility enabled'
            : 'You are hidden from nearby radar',
        icon: value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final audio = AudioService.instance;
    final currentLocale = context.locale.languageCode;

    return Scaffold(
      backgroundColor: PatiiColors.navy,
      appBar: AppBar(
        backgroundColor: PatiiColors.navyElevated,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: PatiiColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: PatiiTypography.display(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: PatiiColors.goldLight,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Account & Profile
          _SectionHeader(title: 'ACCOUNT & PROFILE'),
          const SizedBox(height: 8),
          _SettingsCard(
            child: Column(
              children: [
                if (user != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            PatiiColors.gold.withValues(alpha: 0.2),
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'P',
                          style: PatiiTypography.display(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: PatiiColors.goldLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: PatiiTypography.display(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${user.isGuest ? 'Guest Account' : 'Google Verified'} · Code: ${user.friendCode}',
                              style: PatiiTypography.body(
                                fontSize: 12,
                                color: PatiiColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: PatiiColors.gold, size: 20),
                        tooltip: 'Copy Friend Code',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: user.friendCode));
                          ToastBanner.show(
                            context,
                            'Friend code copied!',
                            icon: Icons.copy_rounded,
                          );
                        },
                      ),
                    ],
                  ),
                  if (user.isGuest) ...[
                    const SizedBox(height: 12),
                    GoldButton(
                      label: 'auth.link_google'.tr(),
                      icon: Icons.g_mobiledata_rounded,
                      height: 42,
                      onPressed: () async {
                        final ok = await ref
                            .read(authProvider.notifier)
                            .linkGoogleWithPrompt();
                        if (context.mounted && ok) {
                          ToastBanner.show(
                            context,
                            'Account linked with Google!',
                            icon: Icons.check_circle_rounded,
                          );
                        }
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Audio & Haptics
          _SectionHeader(title: 'AUDIO & HAPTICS'),
          const SizedBox(height: 8),
          _SettingsCard(
            child: ListenableBuilder(
              listenable: audio,
              builder: (context, _) {
                return Column(
                  children: [
                    _ToggleRow(
                      icon: Icons.volume_up_rounded,
                      title: 'Sound Effects (SFX)',
                      subtitle: 'Card snaps, chips & turn alerts',
                      value: audio.soundEnabled,
                      onChanged: audio.setSoundEnabled,
                    ),
                    if (audio.soundEnabled)
                      _VolumeSlider(
                        value: audio.sfxVolume,
                        onChanged: audio.setSfxVolume,
                      ),
                    const Divider(color: PatiiColors.hairline, height: 20),
                    _ToggleRow(
                      icon: Icons.music_note_rounded,
                      title: 'Background Music (BGM)',
                      subtitle: 'Ambient lobby & table soundtrack',
                      value: audio.musicEnabled,
                      onChanged: audio.setMusicEnabled,
                    ),
                    if (audio.musicEnabled)
                      _VolumeSlider(
                        value: audio.musicVolume,
                        onChanged: audio.setMusicVolume,
                      ),
                    const Divider(color: PatiiColors.hairline, height: 20),
                    _ToggleRow(
                      icon: Icons.vibration_rounded,
                      title: 'Haptic Feedback',
                      subtitle: 'Tactile vibrations on cards & shake',
                      value: audio.vibrationEnabled,
                      onChanged: audio.setVibrationEnabled,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 3. Language
          _SectionHeader(title: 'LANGUAGE'),
          const SizedBox(height: 8),
          _SettingsCard(
            child: Row(
              children: [
                const Icon(Icons.translate_rounded,
                    color: PatiiColors.goldLight, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'App Language',
                    style: PatiiTypography.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ChoiceChip(
                  label: const Text('English'),
                  selected: currentLocale == 'en',
                  selectedColor: PatiiColors.gold,
                  backgroundColor: PatiiColors.navyElevated,
                  labelStyle: TextStyle(
                    color: currentLocale == 'en'
                        ? PatiiColors.navy
                        : PatiiColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (_) => context.setLocale(const Locale('en')),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('नेपाली'),
                  selected: currentLocale == 'ne',
                  selectedColor: PatiiColors.gold,
                  backgroundColor: PatiiColors.navyElevated,
                  labelStyle: TextStyle(
                    color: currentLocale == 'ne'
                        ? PatiiColors.navy
                        : PatiiColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (_) => context.setLocale(const Locale('ne')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Nearby & Privacy
          _SectionHeader(title: 'NEARBY & PRIVACY'),
          const SizedBox(height: 8),
          _SettingsCard(
            child: _ToggleRow(
              icon: Icons.radar_rounded,
              title: 'Discoverable on Radar',
              subtitle: 'Allow nearby Wi-Fi players to detect your device',
              value: _radarDiscoverable,
              onChanged: _toggleRadarVisibility,
            ),
          ),
          const SizedBox(height: 20),

          // 5. App & Updates
          _SectionHeader(title: 'APP & UPDATES'),
          const SizedBox(height: 8),
          _SettingsCard(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.system_update_rounded,
                  title: 'Over-the-Air Updates (Shorebird)',
                  subtitle: 'Auto-update enabled · App v1.1.0+2',
                  onTap: () {
                    ToastBanner.show(
                      context,
                      'Patii checks for Shorebird OTA patches automatically on launch.',
                      icon: Icons.cloud_done_rounded,
                    );
                  },
                ),
                const Divider(color: PatiiColors.hairline, height: 18),
                _ActionTile(
                  icon: Icons.auto_awesome_rounded,
                  title: "What's New (v1.1.0)",
                  subtitle: 'Release notes & latest features',
                  onTap: () => ChangelogDialog.show(context),
                ),
                if (kDebugMode) ...[
                  const Divider(color: PatiiColors.hairline, height: 18),
                  _ActionTile(
                    icon: Icons.palette_outlined,
                    title: 'Developer Component Gallery',
                    subtitle: 'Inspect design tokens & audio studio',
                    onTap: () => Navigator.pushNamed(context, '/dev/gallery'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (user != null)
            GhostButton(
              label: 'auth.sign_out'.tr(),
              icon: Icons.logout_rounded,
              height: 46,
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).signOut();
              },
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: PatiiTypography.bodySmall.copyWith(
          color: PatiiColors.goldLight,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PatiiColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatiiColors.hairline),
      ),
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: PatiiColors.goldLight, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PatiiTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PatiiColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: PatiiTypography.body(
                  fontSize: 11,
                  color: PatiiColors.textMuted,
                ),
              ),
            ],
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
}

class _VolumeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 4, top: 4),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, color: PatiiColors.goldLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PatiiTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PatiiColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: PatiiTypography.body(
                    fontSize: 11,
                    color: PatiiColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: PatiiColors.textMuted),
        ],
      ),
    );
  }
}
