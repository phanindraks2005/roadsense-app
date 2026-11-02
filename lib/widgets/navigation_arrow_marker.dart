import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Blue navigation arrow that rotates to match GPS heading, matching
/// the CSS triangle-with-white-chevron arrow used in the web prototype.
class NavigationArrowMarker extends StatelessWidget {
  final double? headingDeg;

  const NavigationArrowMarker({super.key, this.headingDeg});

  @override
  Widget build(BuildContext context) {
    final angle = (headingDeg ?? 0) * math.pi / 180;

    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: const Size(40, 40),
        painter: _ArrowPainter(),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;

    // Soft shadow ellipse under the arrow.
    final shadowPaint = Paint()..color = const Color.fromRGBO(0, 0, 0, 0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center, size.height - 6),
        width: 22,
        height: 8,
      ),
      shadowPaint,
    );

    // Blue triangle pointing up.
    final trianglePaint = Paint()..color = AppColors.primary;
    final path = Path()
      ..moveTo(center, 2)
      ..lineTo(size.width - 4, size.height - 10)
      ..lineTo(4, size.height - 10)
      ..close();
    canvas.drawPath(path, trianglePaint);

    // White chevron inside.
    final chevronPaint = Paint()..color = Colors.white;
    final chevron = Path()
      ..moveTo(center, size.height * 0.35)
      ..lineTo(center + 6, size.height * 0.62)
      ..lineTo(center, size.height * 0.52)
      ..lineTo(center - 6, size.height * 0.62)
      ..close();
    canvas.drawPath(chevron, chevronPaint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => false;
}
