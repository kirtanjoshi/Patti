import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Player seat: avatar with a live turn-countdown ring, name, and one info pill.
///
/// The ring drains in real time from [remainingSeconds] and turns crimson in
/// the last third, so "whose turn and how long" reads at a glance.
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
  final double avatarSize;

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
    this.avatarSize = 46,
  });

  @override
  State<PlayerSeat> createState() => _PlayerSeatState();
}

class _PlayerSeatState extends State<PlayerSeat> with TickerProviderStateMixin {
  late final AnimationController _countdown;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _countdown = AnimationController(vsync: this, value: 1.0);
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (widget.isCurrentTurn) _startTurn();
  }

  void _startTurn() {
    final total = math.max(1, widget.totalTurnSeconds);
    final remaining = widget.remainingSeconds.clamp(0, total);
    _countdown.value = remaining / total;
    _countdown.animateTo(0, duration: Duration(seconds: remaining));
    _pulse.repeat(reverse: true);
  }

  void _stopTurn() {
    _countdown.stop();
    _countdown.value = 1.0;
    _pulse.stop();
    _pulse.value = 0;
  }

  @override
  void didUpdateWidget(covariant PlayerSeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTurn != oldWidget.isCurrentTurn) {
      if (widget.isCurrentTurn) {
        _startTurn();
        if (!widget.isBot) AudioService.instance.playYourTurnChime();
      } else {
        _stopTurn();
      }
    }
  }

  @override
  void dispose() {
    _countdown.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Stable per-player colour so seats are distinguishable without photos.
  static Color avatarColor(String name) {
    const palette = [
      Color(0xFF4F7CFF),
      Color(0xFF8B5CF6),
      Color(0xFF14B8A6),
      Color(0xFFF97316),
      Color(0xFFEC4899),
      Color(0xFF22C55E),
      Color(0xFFE5484D),
    ];
    final h = name.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
    return palette[h % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final size = widget.avatarSize;
    final ring = size + 10;
    final base = avatarColor(widget.displayName);
    final active = widget.isCurrentTurn;

    return Semantics(
      label: '${widget.displayName}${widget.isBot ? ", Bot" : ""}'
          '${active ? ", Turn active" : ""}${widget.isFolded ? ", Folded" : ""}',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: widget.isFolded ? 0.5 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: ring,
                height: ring,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Ring + glow, repainted by the countdown controller only.
                    AnimatedBuilder(
                      animation: Listenable.merge([_countdown, _pulse]),
                      builder: (context, _) {
                        final p = _countdown.value;
                        final color = p < 0.34
                            ? Color.lerp(PatiiColors.crimsonLight, PatiiColors.gold, p / 0.34)!
                            : PatiiColors.gold;
                        final glow = reduceMotion ? 0.5 : _pulse.value;
                        return Container(
                          width: ring,
                          height: ring,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (active)
                                BoxShadow(
                                  color: color.withValues(alpha: 0.25 + 0.25 * glow),
                                  blurRadius: 10 + 8 * glow,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _TurnTimerPainter(
                              progress: p,
                              isActive: active,
                              color: color,
                            ),
                          ),
                        );
                      },
                    ),

                    // Avatar
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(base, Colors.white, 0.15)!,
                            Color.lerp(base, Colors.black, 0.45)!,
                          ],
                        ),
                        border: Border.all(
                          color: active ? Colors.transparent : Colors.white.withValues(alpha: 0.18),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: widget.avatarUrl != null
                            ? Image.network(widget.avatarUrl!, fit: BoxFit.cover)
                            : widget.isBot
                                ? Icon(Icons.smart_toy_rounded, size: size * 0.5, color: Colors.white)
                                : Center(
                                child: Text(
                                  widget.displayName.isNotEmpty
                                      ? widget.displayName.characters.first.toUpperCase()
                                      : 'P',
                                  style: PatiiTypography.display(
                                    fontSize: size * 0.42,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    if (widget.isFolded)
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: const Icon(Icons.close_rounded, color: PatiiColors.danger, size: 22),
                      ),

                    if (widget.isDealer)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _CornerChip(
                          color: Colors.white,
                          child: Text(
                            'D',
                            style: PatiiTypography.display(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: PatiiColors.navy,
                            ),
                          ),
                        ),
                      ),

                  ],
                ),
              ),
              const SizedBox(height: 2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 92),
                child: Text(
                  widget.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: PatiiTypography.body(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? PatiiColors.goldLight : PatiiColors.textPrimary,
                    height: 1.15,
                  ),
                ),
              ),
              if (widget.infoPillText != null) ...[
                const SizedBox(height: 2),
                Container(
                  constraints: const BoxConstraints(maxWidth: 110),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: PatiiColors.hairline, width: 0.8),
                  ),
                  child: Text(
                    widget.infoPillText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PatiiTypography.body(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.isFolded ? PatiiColors.danger : PatiiColors.textSecondary,
                      height: 1.2,
                    ),
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

class _CornerChip extends StatelessWidget {
  final Color color;
  final Widget child;

  const _CornerChip({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: PatiiColors.navy, width: 1.5),
      ),
      child: child,
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
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 1.5;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _TurnTimerPainter old) =>
      progress != old.progress || isActive != old.isActive || color != old.color;
}
