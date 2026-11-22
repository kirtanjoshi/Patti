import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Press feedback used by every Patii control: quick scale-down, light haptic,
/// dimmed when disabled. Respects the OS "reduce motion" setting.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double pressedScale;
  final bool dimWhenDisabled;

  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.isEnabled = true,
    this.pressedScale = 0.95,
    this.dimWhenDisabled = true,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _active => widget.isEnabled && widget.onPressed != null;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _active ? (_) => _set(true) : null,
      onTapUp: _active ? (_) => _set(false) : null,
      onTapCancel: () => _set(false),
      onTap: _active
          ? () {
              AudioService.instance.playButtonClick();
              HapticFeedback.selectionClick();
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: !reduceMotion && _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _active || !widget.dimWhenDisabled ? 1.0 : 0.4,
          child: widget.child,
        ),
      ),
    );
  }
}

enum _Kind { gold, ghost, danger }

class _PatiiButton extends StatelessWidget {
  final _Kind kind;
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double minWidth;
  final double height;
  final EdgeInsetsGeometry? padding;

  const _PatiiButton({
    required this.kind,
    required this.label,
    this.icon,
    this.onPressed,
    this.isEnabled = true,
    this.minWidth = 0.0,
    this.height = 48.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && onPressed != null;
    // Disabled = neutral, not a faded gold (which reads as muddy brown on felt).
    final (BoxDecoration deco, Color fg) = !enabled
        ? (
            BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PatiiColors.hairline, width: 1),
            ),
            PatiiColors.textMuted,
          )
        : switch (kind) {
            _Kind.gold => (
                BoxDecoration(
                  gradient: PatiiColors.goldButtonGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x66FFF3CF), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: PatiiColors.gold.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                const Color(0xFF241A05),
              ),
            _Kind.ghost => (
                BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: PatiiColors.hairlineStrong, width: 1),
                ),
                PatiiColors.textPrimary,
              ),
            _Kind.danger => (
                BoxDecoration(
                  gradient: PatiiColors.dangerGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: PatiiColors.crimson.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                Colors.white,
              ),
          };

    final compact = height < 40;
    return Semantics(
      button: true,
      enabled: isEnabled && onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onPressed: onPressed,
        isEnabled: isEnabled,
        dimWhenDisabled: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
          padding: padding ??
              EdgeInsets.symmetric(horizontal: compact ? 12 : 18, vertical: 6),
          decoration: deco,
          // widthFactor: 1 => hug the content when width is loose
          // (a plain Center stretched these to full width).
          child: Center(
            widthFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: compact ? 16 : 18, color: fg),
                  SizedBox(width: compact ? 5 : 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: PatiiTypography.display(
                      fontSize: compact ? 13 : 14.5,
                      fontWeight: FontWeight.w700,
                      color: fg,
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Primary action. One per view where possible.
class GoldButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double minWidth;
  final double height;
  final EdgeInsetsGeometry? padding;

  const GoldButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isEnabled = true,
    this.minWidth = 0.0,
    this.height = 48.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) => _PatiiButton(
        kind: _Kind.gold,
        label: label,
        icon: icon,
        onPressed: onPressed,
        isEnabled: isEnabled,
        minWidth: minWidth,
        height: height,
        padding: padding,
      );
}

/// Secondary action: translucent with a white hairline.
class GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double minWidth;
  final double height;
  final EdgeInsetsGeometry? padding;

  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isEnabled = true,
    this.minWidth = 0.0,
    this.height = 48.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) => _PatiiButton(
        kind: _Kind.ghost,
        label: label,
        icon: icon,
        onPressed: onPressed,
        isEnabled: isEnabled,
        minWidth: minWidth,
        height: height,
        padding: padding,
      );
}

/// Destructive action (Pack, Fold, Leave).
class DangerButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double minWidth;
  final double height;
  final EdgeInsetsGeometry? padding;

  const DangerButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isEnabled = true,
    this.minWidth = 0.0,
    this.height = 48.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) => _PatiiButton(
        kind: _Kind.danger,
        label: label,
        icon: icon,
        onPressed: onPressed,
        isEnabled: isEnabled,
        minWidth: minWidth,
        height: height,
        padding: padding,
      );
}
