import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'table_felt.dart';

/// Shared Landscape Casino Table Shell
/// Automatically locks orientation to landscape on entry and restores portrait on exit.
/// Provides the outer table rail, green felt, and the top HUD bar with round info and pot.
class TableShell extends StatefulWidget {
  final Widget child;
  final String gameTitle;
  final String? roundInfo;
  final int? pot;
  final String? trumpSuit;
  final VoidCallback? onLeave;
  final VoidCallback? onRulesTap;
  final TableFeltShape feltShape;

  const TableShell({
    super.key,
    required this.child,
    required this.gameTitle,
    this.roundInfo,
    this.pot,
    this.trumpSuit,
    this.onLeave,
    this.onRulesTap,
    this.feltShape = TableFeltShape.roundedRect,
  });

  @override
  State<TableShell> createState() => _TableShellState();
}

class _TableShellState extends State<TableShell> {
  @override
  void initState() {
    super.initState();
    // Lock table to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore portrait orientation when leaving the table
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _showLeaveConfirmDialog(BuildContext context) {
    if (widget.onLeave != null) {
      widget.onLeave!();
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PatiiColors.navyElevated,
        shape: RoundedRectangleBorder(
          borderRadius: PatiiSpacing.rounded16,
          side: const BorderSide(color: PatiiColors.goldDark, width: 1.2),
        ),
        title: Text(
          'callbreak.leave'.tr(),
          style: PatiiTypography.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: PatiiColors.goldLight,
          ),
        ),
        content: Text(
          'callbreak.leave_confirm'.tr(),
          style: PatiiTypography.poppins(
            fontSize: 14,
            color: PatiiColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'callbreak.stay'.tr(),
              style: PatiiTypography.poppins(
                fontSize: 14,
                color: PatiiColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PatiiColors.crimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text(
              'callbreak.leave'.tr(),
              style: PatiiTypography.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatiiColors.navy,
      body: SafeArea(
        child: TableFelt(
          shape: widget.feltShape,
          child: Stack(
            children: [
              // Main Table Game Content
              Positioned.fill(child: widget.child),

              // Top HUD Bar
              Positioned(
                top: 6.0,
                left: 12.0,
                right: 12.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back / Leave button (guaranteed 48x48 min touch target)
                    Semantics(
                      button: true,
                      label: 'callbreak.leave'.tr(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: PatiiColors.navySurface.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PatiiColors.gold.withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: PatiiColors.goldLight,
                          ),
                          onPressed: () => _showLeaveConfirmDialog(context),
                        ),
                      ),
                    ),

                    // Center Glass Info Pill: Title, Round, Trump, Pot
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: PatiiColors.navySurface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: PatiiColors.goldDark.withValues(alpha: 0.5),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.gameTitle,
                              style: PatiiTypography.cinzel(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: PatiiColors.goldLight,
                              ),
                            ),
                            if (widget.roundInfo != null) ...[
                              const SizedBox(width: 6),
                              const Text(
                                '·',
                                style: TextStyle(color: PatiiColors.goldDark),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.roundInfo!,
                                  style: PatiiTypography.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: PatiiColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (widget.trumpSuit != null) ...[
                              const SizedBox(width: 6),
                              const Text(
                                '·',
                                style: TextStyle(color: PatiiColors.goldDark),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '♠ ${widget.trumpSuit}',
                                style: PatiiTypography.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: PatiiColors.goldLight,
                                ),
                              ),
                            ],
                            if (widget.pot != null) ...[
                              const SizedBox(width: 6),
                              const Text(
                                '·',
                                style: TextStyle(color: PatiiColors.goldDark),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.monetization_on,
                                size: 14,
                                color: PatiiColors.gold,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${widget.pot}',
                                style: PatiiTypography.cinzel(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: PatiiColors.goldLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Right Rules / Info Button (36x36 pill)
                    Semantics(
                      button: true,
                      label: 'Game Rules',
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: PatiiColors.navySurface.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PatiiColors.gold.withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          icon: const Icon(
                            Icons.help_outline,
                            color: PatiiColors.goldLight,
                          ),
                          onPressed: widget.onRulesTap,
                        ),
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
