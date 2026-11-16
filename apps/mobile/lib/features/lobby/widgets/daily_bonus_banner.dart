import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';

/// Hero banner card for Daily Bonus with animated countdown and gold "Claim" CTA.
class DailyBonusBanner extends StatefulWidget {
  final VoidCallback onClaim;
  final int initialSecondsRemaining;

  const DailyBonusBanner({
    super.key,
    required this.onClaim,
    this.initialSecondsRemaining = 15542, // e.g. ~4h 19m
  });

  @override
  State<DailyBonusBanner> createState() => _DailyBonusBannerState();
}

class _DailyBonusBannerState extends State<DailyBonusBanner> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.initialSecondsRemaining;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PatiiSpacing.s16,
        vertical: PatiiSpacing.s4,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: PatiiSpacing.rounded16,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PatiiColors.navyElevated,
              PatiiColors.navySurface,
            ],
          ),
          border: Border.all(
            color: PatiiColors.gold.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: PatiiSpacing.rounded16,
          child: Stack(
            children: [
              // Subtle gold glow in top-left
              Positioned(
                top: -30,
                left: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PatiiColors.gold.withValues(alpha: 0.08),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PatiiSpacing.s12,
                  vertical: PatiiSpacing.s8,
                ),
                child: Row(
                  children: [
                    // Glowing Gift / Chest Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [PatiiColors.goldLight, PatiiColors.goldDark],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: PatiiColors.gold.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.card_giftcard,
                          color: PatiiColors.navy,
                          size: 22,
                        ),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.96, 0.96),
                          end: const Offset(1.04, 1.04),
                          duration: 1800.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(width: PatiiSpacing.s8),

                    // Title & Countdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'lobby.daily_bonus'.tr(),
                            style: PatiiTypography.cinzel(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: PatiiColors.goldLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 12,
                                color: PatiiColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'lobby.bonus_resets_in'.tr(
                                    args: [_formatDuration(_secondsLeft)],
                                  ),
                                  style: PatiiTypography.poppins(
                                    fontSize: 11.5,
                                    color: PatiiColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: PatiiSpacing.s4),

                    // Gold CTA "Claim" button with capped width
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 115),
                      child: GoldButton(
                        label: 'lobby.claim_bonus'.tr(),
                        icon: Icons.stars,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        onPressed: widget.onClaim,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
