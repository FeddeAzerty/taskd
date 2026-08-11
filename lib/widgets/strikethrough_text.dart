import 'package:flutter/material.dart';

class StrikethroughText extends StatelessWidget {
  const StrikethroughText({
    required this.text,
    required this.progress,
    this.style,
    this.strikeColor,
    this.maxLines = 2,
    super.key,
  });

  final String text;
  final double progress;
  final TextStyle? style;

  final Color? strikeColor;

  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: resolved),
          maxLines: maxLines,
          ellipsis: '…',
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        return CustomPaint(
          size: Size(constraints.maxWidth, painter.height),
          painter: _StrikethroughPainter(
            painter: painter,
            progress: progress.clamp(0.0, 1.0),
            color: strikeColor ?? resolved.color ?? Colors.black,
            thickness: (resolved.fontSize ?? 16) * 0.075,
          ),
        );
      },
    );
  }
}

class _StrikethroughPainter extends CustomPainter {
  _StrikethroughPainter({
    required this.painter,
    required this.progress,
    required this.color,
    required this.thickness,
  });

  final TextPainter painter;
  final double progress;
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    painter.paint(canvas, Offset.zero);
    if (progress <= 0) return;

    final lines = painter.computeLineMetrics();
    if (lines.isEmpty) return;

    final totalWidth = lines.fold<double>(0, (sum, l) => sum + l.width);
    var remaining = totalWidth * progress;

    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness.clamp(1.0, 3.0)
      ..strokeCap = StrokeCap.round;

    for (final line in lines) {
      if (remaining <= 0) break;

      final drawn = remaining.clamp(0.0, line.width);

      final y = line.baseline - (line.height - line.descent) * 0.32;
      final startX = line.left;

      canvas.drawLine(Offset(startX, y), Offset(startX + drawn, y), paint);
      remaining -= line.width;
    }
  }

  @override
  bool shouldRepaint(_StrikethroughPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.painter != painter ||
      old.thickness != thickness;
}
