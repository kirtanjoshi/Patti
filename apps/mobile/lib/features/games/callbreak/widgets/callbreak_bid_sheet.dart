import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass_sheet.dart';

/// Single-Row Callbreak Bid Selector (Bids 1 to 8)
/// Designed specifically for landscape layout so that it sits cleanly above the player's hand
/// without ever overlapping seats, buttons, or cards.
class CallbreakBidSheet extends StatefulWidget {
  final int? initialBid;
  final ValueChanged<int> onBidConfirmed;

  const CallbreakBidSheet({
    super.key,
    this.initialBid = 2,
    required this.onBidConfirmed,
  });

  @override
  State<CallbreakBidSheet> createState() => _CallbreakBidSheetState();
}

class _CallbreakBidSheetState extends State<CallbreakBidSheet> {
  late int _selectedBid;

  @override
  void initState() {
    super.initState();
    _selectedBid = widget.initialBid ?? 2;
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Title & Hint
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.gavel,
                size: 15,
                color: PatiiColors.gold,
              ),
              const SizedBox(width: 6),
              Text(
                'callbreak.select_bid'.tr(),
                style: PatiiTypography.cinzel(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: PatiiColors.goldLight,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 8 Circular Bid Buttons (1-8 in a single row) + Confirm CTA
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Single row of circular bid buttons 1 to 8
              ...List.generate(8, (index) {
                final bidValue = index + 1;
                final isSelected = _selectedBid == bidValue;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: 'Bid $bidValue',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedBid = bidValue;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      splashColor: PatiiColors.gold.withValues(alpha: 0.3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isSelected
                              ? PatiiColors.goldButtonGradient
                              : null,
                          color: isSelected
                              ? null
                              : PatiiColors.navyElevated.withValues(alpha: 0.7),
                          border: Border.all(
                            color: isSelected
                                ? PatiiColors.goldLight
                                : PatiiColors.goldDark.withValues(alpha: 0.5),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: PatiiColors.gold.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$bidValue',
                            style: PatiiTypography.cinzel(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? PatiiColors.navy
                                  : PatiiColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(width: PatiiSpacing.s8),

              // Confirm Button
              GoldButton(
                label: 'actions.confirm'.tr(),
                icon: Icons.check,
                height: 36,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                onPressed: () => widget.onBidConfirmed(_selectedBid),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .slideY(
          begin: 0.3,
          end: 0,
          duration: 250.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 200.ms);
  }
}
