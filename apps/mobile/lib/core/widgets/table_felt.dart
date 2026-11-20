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
                return _Surface(radius: r, shape: shape);
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

  const _Surface({required this.radius, required this.shape});

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
          BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(rim),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - rim),
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: PatiiColors.feltGradient),
            child: CustomPaint(
              painter: _FeltDetailPainter(radius: radius - rim),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inner highlight edge, a faint printed line and an edge vignette.
class _FeltDetailPainter extends CustomPainter {
  final double radius;

  _FeltDetailPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Edge vignette
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

    // Inner lip highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.07),
    );

    // Printed table line, inset from the edge like a real felt.
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
  bool shouldRepaint(covariant _FeltDetailPainter old) => old.radius != radius;
}
