import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/api_const.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/toast_banner.dart';

/// Casino-styled dialog that displays a crisp QR code visual
/// for the private room, complete with Room Code, 4-digit PIN,
/// brand badge, and instant share action.
class RoomQrDialog extends StatelessWidget {
  final String roomCode;
  final String pin;

  const RoomQrDialog({
    super.key,
    required this.roomCode,
    required this.pin,
  });

  void _shareRoom(BuildContext context) {
    HapticFeedback.lightImpact();
    final link = ApiConst.roomInviteUrl(roomCode);
    Share.share(
      '🃏 Join my private table on Patii! Code: $roomCode, PIN: $pin. Tap to play: $link',
      subject: 'Join my Patii Table',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: PatiiColors.navyElevated,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: PatiiColors.gold.withValues(alpha: 0.4),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: PatiiColors.gold.withValues(alpha: 0.2),
              blurRadius: 26,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: PatiiColors.gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: PatiiColors.gold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TABLE QR CODE',
                      style: PatiiTypography.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: PatiiColors.goldLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: PatiiColors.textMuted, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // QR Code Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _QrMatrixPainter(code: roomCode),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Room Code & Voice PIN Info Badges
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: PatiiColors.navySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PatiiColors.hairline),
              ),
              child: Row(
                children: [
                  // Room Code
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROOM CODE',
                          style: PatiiTypography.body(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: PatiiColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          roomCode,
                          style: PatiiTypography.display(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: PatiiColors.goldLight,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: PatiiColors.hairline,
                  ),
                  const SizedBox(width: 12),
                  // Voice PIN
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VOICE PIN',
                          style: PatiiTypography.body(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: PatiiColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          pin,
                          style: PatiiTypography.display(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF00E676),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        color: PatiiColors.gold, size: 18),
                    tooltip: 'Copy Code & PIN',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: 'Room: $roomCode, Voice PIN: $pin'));
                      ToastBanner.show(
                        context,
                        'Code & PIN copied!',
                        icon: Icons.copy_rounded,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Share Link Action Button
            SizedBox(
              width: double.infinity,
              child: GoldButton(
                label: 'Share Table Link',
                icon: Icons.share_rounded,
                height: 46,
                onPressed: () => _shareRoom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering a clean, stylized QR code matrix
/// with 3 finder patterns, timing rows, and data modules.
class _QrMatrixPainter extends CustomPainter {
  final String code;

  _QrMatrixPainter({required this.code});

  @override
  void paint(Canvas canvas, Size size) {
    const modules = 21; // Standard 21x21 QR Version 1 grid
    final cellSize = size.width / modules;
    final paintDark = Paint()..color = const Color(0xFF0C1427);

    // Draw finder patterns at 3 corners: top-left, top-right, bottom-left
    _drawFinder(canvas, 0, 0, cellSize, paintDark);
    _drawFinder(canvas, (modules - 7) * cellSize, 0, cellSize, paintDark);
    _drawFinder(canvas, 0, (modules - 7) * cellSize, cellSize, paintDark);

    // Timing patterns
    for (int i = 8; i < modules - 8; i += 2) {
      canvas.drawRect(
          Rect.fromLTWH(i * cellSize, 6 * cellSize, cellSize, cellSize),
          paintDark);
      canvas.drawRect(
          Rect.fromLTWH(6 * cellSize, i * cellSize, cellSize, cellSize),
          paintDark);
    }

    // Pseudo-random data modules derived from code hash
    final seed = code.hashCode.abs();
    final random = math.Random(seed);

    for (int row = 0; row < modules; row++) {
      for (int col = 0; col < modules; col++) {
        // Skip finder pattern zones
        if ((row < 8 && col < 8) ||
            (row < 8 && col >= modules - 8) ||
            (row >= modules - 8 && col < 8)) {
          continue;
        }
        // Skip timing lines
        if (row == 6 || col == 6) continue;

        // Skip center chip badge zone (rows 8-12, cols 8-12)
        if (row >= 8 && row <= 12 && col >= 8 && col <= 12) continue;

        if (random.nextDouble() > 0.46) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  col * cellSize + 0.3, row * cellSize + 0.3, cellSize - 0.6, cellSize - 0.6),
              const Radius.circular(1.5),
            ),
            paintDark,
          );
        }
      }
    }

    // Center Gold Casino Chip Badge
    final center = Offset(size.width / 2, size.height / 2);
    final badgePaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawCircle(center, cellSize * 2.3, badgePaint);

    final innerBadgePaint = Paint()..color = const Color(0xFF070D1B);
    canvas.drawCircle(center, cellSize * 1.9, innerBadgePaint);

    // Center text 'P'
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '♠',
        style: TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );
  }

  void _drawFinder(
      Canvas canvas, double left, double top, double cellSize, Paint paint) {
    // 7x7 outer square
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, 7 * cellSize, 7 * cellSize),
        const Radius.circular(4),
      ),
      paint,
    );
    // 5x5 inner white cutout
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(
          left + cellSize, top + cellSize, 5 * cellSize, 5 * cellSize),
      whitePaint,
    );
    // 3x3 inner dark core
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            left + (2 * cellSize), top + (2 * cellSize), 3 * cellSize, 3 * cellSize),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) {
    return oldDelegate.code != code;
  }
}
