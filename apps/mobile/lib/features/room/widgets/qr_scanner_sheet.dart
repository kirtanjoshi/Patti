import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons.dart';

/// Animated QR Scanner Viewfinder BottomSheet.
/// Features a dark casino viewfinder, moving laser scan line,
/// and instant simulated scan / quick code entry.
class QrScannerSheet extends StatefulWidget {
  final ValueChanged<String> onCodeScanned;

  const QrScannerSheet({
    super.key,
    required this.onCodeScanned,
  });

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrScannerSheet(
        onCodeScanned: (code) {
          Navigator.of(ctx).pop(code);
        },
      ),
    );
  }

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _laserController;
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _triggerInstantScan([String code = 'PAT888']) {
    HapticFeedback.mediumImpact();
    widget.onCodeScanned(code);
  }

  void _submitManual() {
    final text = _manualController.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onCodeScanned(text.toUpperCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: PatiiColors.navyElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PatiiColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
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
                      Icons.qr_code_scanner_rounded,
                      color: PatiiColors.gold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SCAN ROOM QR CODE',
                    style: PatiiTypography.display(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: PatiiColors.goldLight,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: PatiiColors.textMuted, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Viewfinder Container with Animated Laser
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF060B17),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: PatiiColors.gold.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Viewfinder Corner Brackets
                  CustomPaint(
                    size: const Size(220, 220),
                    painter: _ViewfinderCornersPainter(),
                  ),

                  // Animated Scanning Laser Line
                  AnimatedBuilder(
                    animation: _laserController,
                    builder: (context, _) {
                      final topOffset = 20.0 + (180.0 * _laserController.value);
                      return Positioned(
                        top: topOffset,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 2.2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFFFF3366),
                                PatiiColors.gold,
                                Color(0xFFFF3366),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF3366)
                                    .withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Center subtle hint
                  Positioned(
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Align QR Code within frame',
                        style: PatiiTypography.body(
                          fontSize: 10,
                          color: PatiiColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Instant Simulated Scan Button (for instant testing/camera simulation)
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              label: 'Instant Simulated Camera Scan',
              icon: Icons.camera_alt_rounded,
              height: 44,
              onPressed: () => _triggerInstantScan('PAT777'),
            ),
          ),
          const SizedBox(height: 14),

          // Manual Code Quick Entry
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualController,
                  textCapitalization: TextCapitalization.characters,
                  style: PatiiTypography.body(
                    fontSize: 13,
                    color: PatiiColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: PatiiColors.navySurface,
                    hintText: 'Or enter code manually',
                    hintStyle: PatiiTypography.body(
                      fontSize: 12,
                      color: PatiiColors.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: PatiiColors.hairline),
                    ),
                  ),
                  onSubmitted: (_) => _submitManual(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatiiColors.navySurface,
                  foregroundColor: PatiiColors.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: PatiiColors.hairline),
                  ),
                ),
                onPressed: _submitManual,
                child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewfinderCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PatiiColors.gold
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    const cornerLength = 26.0;
    const inset = 24.0;
    final w = size.width - inset;
    final h = size.height - inset;

    // Top-left
    canvas.drawLine(
        const Offset(inset, inset), Offset(inset + cornerLength, inset), paint);
    canvas.drawLine(
        const Offset(inset, inset), Offset(inset, inset + cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(w, inset), Offset(w - cornerLength, inset), paint);
    canvas.drawLine(Offset(w, inset), Offset(w, inset + cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(inset, h), Offset(inset + cornerLength, h), paint);
    canvas.drawLine(Offset(inset, h), Offset(inset, h - cornerLength), paint);

    // Bottom-right
    canvas.drawLine(Offset(w, h), Offset(w - cornerLength, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
