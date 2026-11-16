import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Base scaleable animated button wrapper
class _PatiiAnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const _PatiiAnimatedPressable({
    required this.child,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  State<_PatiiAnimatedPressable> createState() => _PatiiAnimatedPressableState();
}

class _PatiiAnimatedPressableState extends State<_PatiiAnimatedPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.isEnabled && widget.onPressed != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.isEnabled && widget.onPressed != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: !disableAnimations && _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Opacity(
          opacity: widget.isEnabled && widget.onPressed != null ? 1.0 : 0.45,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Gold CTA Button
/// Vertical gradient goldLight -> gold -> goldDark, dark navy text, top inner highlight, soft shadow.
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
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled && onPressed != null,
      label: label,
      child: _PatiiAnimatedPressable(
        onPressed: onPressed,
        isEnabled: isEnabled,
        child: Container(
          constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            gradient: PatiiColors.goldButtonGradient,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: PatiiColors.goldLight,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: PatiiColors.goldDark.withValues(alpha: 0.4),
                blurRadius: 8.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: PatiiColors.navy),
                  const SizedBox(width: 8.0),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: PatiiTypography.buttonLabel,
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

/// Ghost Button (Outlined in Gold with translucent Navy surface)
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
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled && onPressed != null,
      label: label,
      child: _PatiiAnimatedPressable(
        onPressed: onPressed,
        isEnabled: isEnabled,
        child: Container(
          constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: PatiiColors.navySurface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: PatiiColors.gold.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: PatiiColors.goldLight),
                  const SizedBox(width: 8.0),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: PatiiTypography.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PatiiColors.goldLight,
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

/// Danger Button (Nepali Crimson background with white text)
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
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled && onPressed != null,
      label: label,
      child: _PatiiAnimatedPressable(
        onPressed: onPressed,
        isEnabled: isEnabled,
        child: Container(
          constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: PatiiColors.crimson,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: PatiiColors.crimson.withValues(alpha: 0.35),
                blurRadius: 6.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8.0),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: PatiiTypography.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
