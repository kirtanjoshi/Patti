import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/chips.dart';

/// Central Pot and Stakes display for the Teen Patti landscape table.
/// Features dynamic 3D chip stacks, animated pot counter, and current stake indicator.
class TeenPattiPotCenter extends StatefulWidget {
  final int pot;
  final int currentStake;
  final int? lastBetAmount;

  const TeenPattiPotCenter({
    super.key,
    required this.pot,
    required this.currentStake,
    this.lastBetAmount,
  });

  @override
  State<TeenPattiPotCenter> createState() => _TeenPattiPotCenterState();
}

class _TeenPattiPotCenterState extends State<TeenPattiPotCenter> {
  int _lastPot = 0;

  @override
  void initState() {
    super.initState();
    _lastPot = widget.pot;
  }

  @override
  void didUpdateWidget(covariant TeenPattiPotCenter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pot != oldWidget.pot) {
      _lastPot = widget.pot;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedPot = NumberFormat('#,###').format(widget.pot);

    return Semantics(
      label: '${'teenpatti.pot'.tr()}: $formattedPot, ${'teenpatti.stake'.tr()}: ${widget.currentStake}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pot Glass Pill with Cinzel Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: PatiiColors.navySurface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: PatiiColors.gold.withValues(alpha: 0.5),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  size: 15,
                  color: PatiiColors.gold,
                ),
                const SizedBox(width: 5),
                Text(
                  '${'teenpatti.pot'.tr().toUpperCase()}: $formattedPot',
                  style: PatiiTypography.cinzel(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: PatiiColors.goldLight,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          )
              .animate(
                target: _lastPot != widget.pot ? 1.0 : 0.0,
                key: ValueKey(widget.pot),
              )
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1.06, 1.06),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 6),

          // Central 3D Casino Chip Stacks
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChipStack(
                totalAmount: widget.pot ~/ 2,
                chipSize: 30.0,
                maxVisibleChips: 4,
              ),
              const SizedBox(width: 4),
              ChipStack(
                totalAmount: widget.pot,
                chipSize: 34.0,
                maxVisibleChips: 5,
              ),
              const SizedBox(width: 4),
              ChipStack(
                totalAmount: widget.pot ~/ 3,
                chipSize: 28.0,
                maxVisibleChips: 3,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Stake Sub-Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: PatiiColors.goldDark.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              '${'teenpatti.stake'.tr()}: ${widget.currentStake} (${'teenpatti.blind'.tr()}: ${widget.currentStake} · ${'teenpatti.seen'.tr()}: ${widget.currentStake * 2})',
              style: PatiiTypography.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: PatiiColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
