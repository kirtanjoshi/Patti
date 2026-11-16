import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// ToastBanner Widget
/// Centered gold-bordered banner for events (e.g. "Bot 2 wins the trick", "You saw the maal!").
class ToastBanner extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? accentColor;

  const ToastBanner({
    super.key,
    required this.message,
    this.icon,
    this.accentColor,
  });

  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastBannerOverlay(
        message: message,
        icon: icon,
        onDismiss: () => entry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = accentColor ?? PatiiColors.goldLight;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: PatiiColors.navySurface.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: goldColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: PatiiColors.goldDark.withValues(alpha: 0.35),
                  blurRadius: 16.0,
                  spreadRadius: 1.0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: goldColor),
                  const SizedBox(width: 8.0),
                ],
                Text(
                  message,
                  style: PatiiTypography.cinzel(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                    color: goldColor,
                    letterSpacing: 0.5,
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

class _ToastBannerOverlay extends StatefulWidget {
  final String message;
  final IconData? icon;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastBannerOverlay({
    required this.message,
    this.icon,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastBannerOverlay> createState() => _ToastBannerOverlayState();
}

class _ToastBannerOverlayState extends State<_ToastBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 64.0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: ToastBanner(
                message: widget.message,
                icon: widget.icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
