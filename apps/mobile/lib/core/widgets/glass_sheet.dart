import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Luxury Glass Panel for Casino HUD and Overlays
/// NavySurface at 85% opacity + BackdropFilter blur 12 + 1px border white at 10%.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? customBgColor;
  final Border? customBorder;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8.0),
    this.borderRadius,
    this.customBgColor,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? PatiiSpacing.rounded16;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: customBgColor ??
                PatiiColors.navyElevated.withValues(alpha: 0.82),
            borderRadius: radius,
            border: customBorder ??
                Border.all(
                  color: PatiiColors.hairline,
                  width: 1.0,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Slide-up Glass Bottom Sheet for Table Actions (Bids, Melds, Settings)
/// Stays above hand without obscuring it.
class GlassSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onClose;
  final double? maxHeight;

  const GlassSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          maxHeight != null ? BoxConstraints(maxHeight: maxHeight!) : null,
      decoration: BoxDecoration(
        color: PatiiColors.navySurface.withValues(alpha: 0.90),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
        border: Border.all(
          color: PatiiColors.hairlineStrong,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 36.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),

                  if (title != null) ...[
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: PatiiColors.goldLight,
                          ),
                        ),
                        if (onClose != null)
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 20, color: PatiiColors.textSecondary),
                            onPressed: onClose,
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8.0),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
