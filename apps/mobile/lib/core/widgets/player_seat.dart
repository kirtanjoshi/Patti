import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Casino Player Seat Widget
/// 52px circular avatar, turn timer ring, dealer chip, bot badge, glass info pill.
class PlayerSeat extends StatefulWidget {
  final String displayName;
  final String? avatarUrl;
  final bool isCurrentTurn;
  final bool isDealer;
  final bool isBot;
  final bool isFolded;
  final String? infoPillText;
  final int totalTurnSeconds;
  final int remainingSeconds;
  final VoidCallback? onTap;

  const PlayerSeat({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.isCurrentTurn = false,
    this.isDealer = false,
    this.isBot = false,
    this.isFolded = false,
    this.infoPillText,
    this.totalTurnSeconds = 15,
    this.remainingSeconds = 15,
    this.onTap,
  });

  @override
  State<PlayerSeat> createState() => _PlayerSeatState();
}

class _PlayerSeatState extends State<PlayerSeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 4.0, end: 14.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isCurrentTurn) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PlayerSeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTurn != oldWidget.isCurrentTurn) {
      if (widget.isCurrentTurn) {
        _pulseController.repeat(reverse: true);
        if (!widget.isBot) {
          AudioService.instance.playYourTurnChime();
        }
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final isUrgent = widget.remainingSeconds <= 5;
    final timerColor = isUrgent ? PatiiColors.crimson : PatiiColors.gold;

    return Semantics(
      label: '${widget.displayName}${widget.isBot ? ", Bot" : ""}${widget.isCurrentTurn ? ", Turn active" : ""}',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Avatar with Turn Timer Ring & Dealer / Bot Chips
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Pulsing Gold Glow on Turn
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final blur = disableAnimations || !widget.isCurrentTurn
                        ? 6.0
                        : _pulseAnimation.value;
                    return Container(
                      width: 62.0,
                      height: 62.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (widget.isCurrentTurn)
                            BoxShadow(
                              color: timerColor.withValues(alpha: 0.7),
                              blurRadius: blur,
                              spreadRadius: 2.0,
                            ),
                        ],
                      ),
                    );
                  },
                ),

                // Timer Arc Ring
                CustomPaint(
                  size: const Size(60, 60),
                  painter: _TurnTimerPainter(
                    progress: widget.totalTurnSeconds > 0
                        ? widget.remainingSeconds / widget.totalTurnSeconds
                        : 0.0,
                    isActive: widget.isCurrentTurn,
                    color: timerColor,
                  ),
                ),

                // 52px Circular Avatar
                Container(
                  width: 52.0,
                  height: 52.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PatiiColors.navyElevated,
                    border: Border.all(
                      color: widget.isCurrentTurn ? timerColor : Colors.white.withValues(alpha: 0.2),
                      width: 2.0,
                    ),
                  ),
                  child: ClipOval(
                    child: widget.isFolded
                        ? Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            child: const Center(
                              child: Icon(Icons.close, color: PatiiColors.danger, size: 24),
                            ),
                          )
                        : (widget.avatarUrl != null
                            ? Image.network(widget.avatarUrl!, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  widget.displayName.isNotEmpty
                                      ? widget.displayName[0].toUpperCase()
                                      : 'P',
                                  style: PatiiTypography.cinzel(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: PatiiColors.goldLight,
                                  ),
                                ),
                              )),
                  ),
                ),

                // Dealer "D" Chip (Top-Left)
                if (widget.isDealer)
                  Positioned(
                    top: -4,
                    left: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: PatiiColors.goldButtonGradient,
                        border: Border.all(color: PatiiColors.navy, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'D',
                          style: PatiiTypography.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: PatiiColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Bot Badge (Top-Right)
                if (widget.isBot)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: PatiiColors.navyElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: PatiiColors.gold.withValues(alpha: 0.5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.smart_toy, size: 9, color: PatiiColors.goldLight),
                          const SizedBox(width: 2),
                          Text(
                            'BOT',
                            style: PatiiTypography.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: PatiiColors.goldLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4.0),

            // Player Name
            SizedBox(
              width: 80,
              child: Text(
                widget.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: PatiiTypography.poppins(
                  fontSize: 12,
                  fontWeight: widget.isCurrentTurn ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isCurrentTurn ? PatiiColors.goldLight : PatiiColors.textPrimary,
                ),
              ),
            ),

            // Glass Info Pill (Never a rectangle panel!)
            if (widget.infoPillText != null) ...[
              const SizedBox(height: 2.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: PatiiColors.navySurface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: widget.isCurrentTurn
                        ? PatiiColors.gold.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  widget.infoPillText!,
                  style: PatiiTypography.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.isFolded ? PatiiColors.danger : PatiiColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TurnTimerPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final Color color;

  _TurnTimerPainter({
    required this.progress,
    required this.isActive,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, trackPaint);

    // Active sweep
    final sweepPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TurnTimerPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      isActive != oldDelegate.isActive ||
      color != oldDelegate.color;
}
