import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum TableFeltShape {
  roundedRect,
  oval,
}

/// Landscape table surface.
///
/// Ink backdrop, a near edge-to-edge felt lit from above with a slim dark rim
/// and a faint printed "betting line". The [child] is laid over the WHOLE
/// area and is not clipped to the felt, so hands can bleed off the bottom
/// edge and seats can sit on the rim the way real table apps do.
class TableFelt extends StatelessWidget {
  final Widget child;
  final TableFeltShape shape;
  final String watermarkText;

  const TableFelt({
    super.key,
    required this.child,
    this.shape = TableFeltShape.roundedRect,
    this.watermarkText = 'PATII',
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.2,
          colors: [Color(0xFF14203A), PatiiColors.navy],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: LayoutBuilder(
              builder: (context, c) {
                final r = shape == TableFeltShape.oval
                    ? c.maxHeight / 2
                    : (c.maxHeight * 0.16).clamp(20.0, 64.0);
                return _Surface(
                  radius: r,
                  shape: shape,
                  watermarkText: watermarkText,
                );
              },
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  final double radius;
  final TableFeltShape shape;
  final String watermarkText;

  const _Surface({
    required this.radius,
    required this.shape,
    this.watermarkText = 'PATII',
  });

  @override
  Widget build(BuildContext context) {
    const rim = 7.0;
    return DecoratedBox(
      // Rim: dark, slightly lit on top edge.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF243A33), PatiiColors.feltRim, Color(0xFF050B09)],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(rim),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - rim),
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: PatiiColors.feltGradient),
            child: CustomPaint(
              painter: _FeltDetailPainter(
                radius: radius - rim,
                watermarkText: watermarkText,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inner highlight edge, woven cloth texture, center watermark, faint printed line and vignette.
class _FeltDetailPainter extends CustomPainter {
  final double radius;
  final String watermarkText;

  _FeltDetailPainter({
    required this.radius,
    this.watermarkText = 'PATII',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final feltRRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.save();
    canvas.clipRRect(feltRRect);

    // 1. Subtle woven baize texture (interwoven micro-strokes simulating cloth grain)
    final weaveLight = Paint()
      ..color = Colors.white.withValues(alpha: 0.012)
      ..strokeWidth = 0.5;
    final weaveDark = Paint()
      ..color = Colors.black.withValues(alpha: 0.016)
      ..strokeWidth = 0.5;

    const step = 6.0;
    final totalW = size.width;
    final totalH = size.height;

    for (double x = -totalH; x < totalW; x += step * 2) {
      canvas.drawLine(Offset(x, 0), Offset(x + totalH, totalH), weaveLight);
    }
    for (double x = 0; x < totalW + totalH; x += step * 2) {
      canvas.drawLine(Offset(x, 0), Offset(x - totalH, totalH), weaveDark);
    }

    // 2. Faint central casino watermark
    if (watermarkText.isNotEmpty && size.width > 200 && size.height > 150) {
      final textSpan = TextSpan(
        text: '❖  $watermarkText  ❖',
        style: TextStyle(
          fontSize: (size.shortestSide * 0.06).clamp(11.0, 20.0),
          fontWeight: FontWeight.w800,
          letterSpacing: 5.0,
          color: Colors.white.withValues(alpha: 0.032),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2 - (size.height * 0.05),
      );
      textPainter.paint(canvas, textOffset);
    }

    canvas.restore();

    // 3. Edge vignette (subtle darkening towards the rail)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.0,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.38)],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );

    // 4. Inner lip highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.08),
    );

    // 5. Printed table line, inset from the edge like a real felt.
    final inset = size.shortestSide * 0.16;
    final line = rect.deflate(inset);
    if (line.width > 40 && line.height > 40) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(line, Radius.circular(line.height / 2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.05),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FeltDetailPainter old) =>
      old.radius != radius || old.watermarkText != watermarkText;
}
