import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';

/// Compact daily-bonus tile: gift, live countdown, and the whole tile claims.
class DailyBonusBanner extends StatefulWidget {
  final VoidCallback onClaim;
  final int initialSecondsRemaining;

  const DailyBonusBanner({
    super.key,
    required this.onClaim,
    this.initialSecondsRemaining = 15542,
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
        setState(() => _secondsLeft--);
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

  String _format(int s) =>
      '${(s ~/ 3600).toString().padLeft(2, '0')}:${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget gift = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PatiiColors.goldButtonGradient,
        boxShadow: [
          BoxShadow(
              color: PatiiColors.gold.withValues(alpha: 0.35), blurRadius: 12)
        ],
      ),
      child:
          const Icon(Icons.redeem_rounded, color: Color(0xFF241A05), size: 20),
    );
    if (!reduceMotion) {
      gift = gift
          .animate(onPlay: (c) => c.repeat())
          .then(delay: 2400.ms)
          .shake(hz: 6, rotation: 0.08, duration: 500.ms);
    }

    return Semantics(
      button: true,
      label: '${'lobby.daily_bonus'.tr()}, ${'lobby.claim_bonus'.tr()}',
      excludeSemantics: true,
      child: Pressable(
        onPressed: widget.onClaim,
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PatiiColors.gold.withValues(alpha: 0.16),
                PatiiColors.navySurface
              ],
            ),
            border: Border.all(color: PatiiColors.gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              gift,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lobby.daily_bonus'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PatiiTypography.display(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _format(_secondsLeft),
                      style: PatiiTypography.display(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PatiiColors.goldLight,
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
