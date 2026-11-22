import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Center pot and current stake display for Teen Patti with animated chip toss effect.
class TeenPattiPotWidget extends StatefulWidget {
  final int pot;
  final int currentStake;
  final int? lastBetAmount;

  const TeenPattiPotWidget({
    super.key,
    required this.pot,
    required this.currentStake,
    this.lastBetAmount,
  });

  @override
  State<TeenPattiPotWidget> createState() => _TeenPattiPotWidgetState();
}

class _TeenPattiPotWidgetState extends State<TeenPattiPotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _chipController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _chipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.1).animate(
      CurvedAnimation(parent: _chipController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _chipController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _chipController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant TeenPattiPotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pot != oldWidget.pot) {
      _chipController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _chipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label:
          '${'teenpatti.pot'.tr()}: ${widget.pot}, ${'teenpatti.current_stake'.tr()}: ${widget.currentStake}',
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Main Pot and Stake Pill Container
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chips Stack Icon
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.toll_rounded,
                    size: 20.0,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8.0),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated Pot Counter
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      tween: Tween<double>(
                          begin: widget.pot.toDouble(),
                          end: widget.pot.toDouble()),
                      builder: (context, value, child) {
                        return Text(
                          '${'teenpatti.pot'.tr()}: ${value.toInt()}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        );
                      },
                    ),
                    Text(
                      '${'teenpatti.current_stake'.tr()}: ${widget.currentStake}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Flying / Tossed Chip Animation
          Positioned(
            bottom: 32.0,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.2),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 12.0,
                          color: colorScheme.onPrimary,
                        ),
                        Text(
                          '${widget.lastBetAmount ?? widget.currentStake}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
