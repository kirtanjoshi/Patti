import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import 'audio_settings_sheet.dart';
import 'coin_counter.dart';
import 'package:patii_engine/patii_engine.dart' as engine;
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'buttons.dart';
import 'suit_icon.dart';
import 'table_felt.dart';

/// Shared landscape table shell.
///
/// Locks landscape while mounted. The HUD lives in the two top corners
/// (leave + title on the left, trump/pot/rules on the right) so the
/// top-centre stays free for the opposite player's seat.
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    AudioService.instance.enterTable();
  }

  @override
  void dispose() {
    AudioService.instance.exitTable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _leave(BuildContext context) {
    if (widget.onLeave != null) {
      widget.onLeave!();
      return;
    }
    showDialog(
      context: context,
      barrierColor: PatiiColors.scrim,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: PatiiColors.crimsonLight),
        title: Text('callbreak.leave'.tr(), textAlign: TextAlign.center),
        content:
            Text('callbreak.leave_confirm'.tr(), textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          GhostButton(
            label: 'callbreak.stay'.tr(),
            height: 44,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          DangerButton(
            label: 'callbreak.leave'.tr(),
            height: 44,
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  engine.Suit? get _trump => switch (widget.trumpSuit?.toLowerCase()) {
        'spades' || 's' || '♠' => engine.Suit.S,
        'hearts' || 'h' || '♥' => engine.Suit.H,
        'diamonds' || 'd' || '♦' => engine.Suit.D,
        'clubs' || 'c' || '♣' => engine.Suit.C,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final trump = _trump;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context);
      },
      child: Scaffold(
        backgroundColor: PatiiColors.navy,
        body: TableFelt(
          shape: widget.feltShape,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: widget.child),

                // Top-left: leave + title
                Positioned(
                  top: 8,
                  left: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HudIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'callbreak.leave'.tr(),
                        onPressed: () => _leave(context),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.gameTitle,
                            style: PatiiTypography.display(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          if (widget.roundInfo != null)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                widget.roundInfo!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PatiiTypography.body(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: PatiiColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Top-right: trump, pot, rules
                Positioned(
                  top: 8,
                  right: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.trumpSuit != null)
                        HudChip(
                          semanticLabel: 'Trump ${widget.trumpSuit}',
                          leading: trump != null
                              ? Container(
                                  width: 18,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: PatiiColors.cardFace,
                                    shape: BoxShape.circle,
                                  ),
                                  child: SuitIcon(
                                    suit: trump,
                                    size: 11,
                                    color: trump == engine.Suit.H ||
                                            trump == engine.Suit.D
                                        ? PatiiColors.suitRed
                                        : PatiiColors.suitBlack,
                                  ),
                                )
                              : null,
                          label: 'TRUMP',
                          value: trump == null ? widget.trumpSuit : null,
                        ),
                      if (widget.pot != null) ...[
                        const SizedBox(width: 6),
                        HudChip(
                          semanticLabel: 'Pot ${widget.pot}',
                          leading: const CoinGlyph(size: 16),
                          value: CoinCounter.formatCoins(widget.pot!),
                        ),
                      ],
                      const SizedBox(width: 6),
                      HudIconButton(
                        icon: Icons.volume_up_rounded,
                        semanticLabel: 'Audio Settings',
                        onPressed: () => AudioSettingsSheet.show(context),
                      ),
                      const SizedBox(width: 6),
                      HudIconButton(
                        icon: Icons.question_mark_rounded,
                        semanticLabel: 'Game Rules',
                        onPressed: widget.onRulesTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small translucent capsule used in the table HUD.
class HudChip extends StatelessWidget {
  final Widget? leading;
  final String? label;
  final String? value;
  final String semanticLabel;

  const HudChip({
    super.key,
    this.leading,
    this.label,
    this.value,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) leading!,
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(label!,
                    style: PatiiTypography.eyebrow(
                        fontSize: 9.5, color: PatiiColors.textSecondary)),
              ],
              if (value != null) ...[
                const SizedBox(width: 6),
                Text(
                  value!,
                  style: PatiiTypography.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PatiiColors.goldLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Round translucent icon button for HUDs (48dp touch target, 36dp visual).
class HudIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  const HudIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(
        onPressed: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Icon(icon, size: 19, color: PatiiColors.textPrimary),
        ),
      ),
    );
  }
}
