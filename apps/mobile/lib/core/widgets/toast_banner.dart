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
    final accent = accentColor ?? PatiiColors.gold;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
            child: Container(
              padding: EdgeInsets.fromLTRB(icon != null ? 8 : 18, 8, 18, 8),
              decoration: BoxDecoration(
                color: PatiiColors.navyElevated.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: PatiiColors.hairlineStrong),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.16),
                      ),
                      child: Icon(icon, size: 15, color: accent),
                    ),
                    const SizedBox(width: 10.0),
                  ],
                  Flexible(
                    child: Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PatiiTypography.body(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: PatiiColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
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
      top: MediaQuery.paddingOf(context).top + 52.0,
      left: 16,
      right: 16,
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
