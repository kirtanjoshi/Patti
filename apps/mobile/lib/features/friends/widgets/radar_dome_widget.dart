import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

/// Visually compelling Sonar Radar Dome with rotating sweep beam,
/// distance rings, expanding sonar ripples, and interactive player blips.
class RadarDomeWidget extends StatelessWidget {
  final Animation<double> animation;
  final double radiusKm;
  final List<NearbyPlayerModel> players;
  final NearbyPlayerModel? selectedPlayer;
  final ValueChanged<NearbyPlayerModel>? onSelectPlayer;

  const RadarDomeWidget({
    super.key,
    required this.animation,
    required this.radiusKm,
    this.players = const [],
    this.selectedPlayer,
    this.onSelectPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF070D1B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: PatiiColors.gold.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: PatiiColors.gold.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radar background and sweeping beam
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(double.infinity, 230),
                  painter: _RadarPainter(
                    sweepAngle: animation.value * 2 * math.pi,
                    radiusKm: radiusKm,
                    pulseValue: animation.value,
                  ),
                );
              },
            ),

            // Center YOU marker
            _buildCenterBeacon(),

            // Top-left live radar status pill
            Positioned(
              top: 12,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PatiiColors.navy.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: PatiiColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00E676),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RADAR ACTIVE',
                      style: PatiiTypography.body(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: PatiiColors.goldLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-right radius badge
            Positioned(
              top: 12,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PatiiColors.navy.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PatiiColors.hairline),
                ),
                child: Text(
                  '${radiusKm.toInt()} KM RANGE',
                  style: PatiiTypography.body(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: PatiiColors.textMuted,
                  ),
                ),
              ),
            ),

            // Interactive player blips plotted on radar
            ..._buildPlayerBlips(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterBeacon() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PatiiColors.navySurface,
            border: Border.all(color: PatiiColors.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: PatiiColors.gold.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_pin_circle_rounded,
            color: PatiiColors.gold,
            size: 18,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: PatiiColors.navy.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'YOU',
            style: PatiiTypography.body(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: PatiiColors.gold,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPlayerBlips(BuildContext context) {
    if (players.isEmpty) return const [];

    return players.map((player) {

      // Deterministic angle & distance based on player ID and distance
      final angle = (player.userId.hashCode % 360) * (math.pi / 180);
      final maxDistanceMeters = radiusKm * 1000;
      final fraction = (player.distanceMeters / maxDistanceMeters).clamp(0.25, 0.88);

      final radarRadius = 88.0; // Half height constrained radius
      final dx = math.cos(angle) * (radarRadius * fraction);
      final dy = math.sin(angle) * (radarRadius * fraction);

      final isSelected = selectedPlayer?.userId == player.userId;

      return Transform.translate(
        offset: Offset(dx, dy),
        child: GestureDetector(
          onTap: () => onSelectPlayer?.call(player),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? PatiiColors.gold : PatiiColors.navySurface,
              border: Border.all(
                color: isSelected ? Colors.white : PatiiColors.goldLight,
                width: isSelected ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? PatiiColors.gold : const Color(0xFF00E5FF))
                      .withValues(alpha: 0.6),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 2 : 1,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: isSelected ? 13 : 10,
              backgroundColor: PatiiColors.navyElevated,
              child: Text(
                player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: isSelected ? 11 : 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? PatiiColors.gold : Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final double radiusKm;
  final double pulseValue;

  _RadarPainter({
    required this.sweepAngle,
    required this.radiusKm,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width / 2, size.height / 2) - 14;

    // 1. Concentric Range Rings (Sonar rings)
    final ringPaint = Paint()
      ..color = PatiiColors.gold.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final r = maxRadius * (i / 3);
      canvas.drawCircle(center, r, ringPaint);
    }

    // Outer border ring
    final outerRingPaint = Paint()
      ..color = PatiiColors.gold.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, maxRadius, outerRingPaint);

    // 2. Crosshair grid lines
    final gridPaint = Paint()
      ..color = PatiiColors.gold.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      gridPaint,
    );

    // 3. Expanding Sonar Ripple Wave
    final rippleRadius = maxRadius * pulseValue;
    final ripplePaint = Paint()
      ..color = PatiiColors.gold.withValues(alpha: (1.0 - pulseValue) * 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, rippleRadius, ripplePaint);

    // 4. Rotating Radar Sweeping Beam (SweepGradient cone)
    final sweepRect = Rect.fromCircle(center: center, radius: maxRadius);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi / 2, // 90 degree sweeping fan
        colors: [
          PatiiColors.gold.withValues(alpha: 0.0),
          PatiiColors.gold.withValues(alpha: 0.38),
        ],
        transform: GradientRotation(sweepAngle),
      ).createShader(sweepRect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Leading sweep needle line
    final needlePaint = Paint()
      ..color = PatiiColors.goldLight.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final leadingAngle = sweepAngle + (math.pi / 2);
    final needleEnd = Offset(
      center.dx + math.cos(leadingAngle) * maxRadius,
      center.dy + math.sin(leadingAngle) * maxRadius,
    );
    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.radiusKm != radiusKm;
  }
}
