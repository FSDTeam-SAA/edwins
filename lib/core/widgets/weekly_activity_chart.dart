import 'package:flutter/material.dart';
import 'package:language_app/app/theme/app_style.dart';

class WeeklyActivityChart extends StatelessWidget {
  final Map<String, int> days;
  final int totalCount;

  const WeeklyActivityChart({
    super.key,
    required this.days,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 343,
      height: 224, // Exact height from your UI layout
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Y-Axis Labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [100, 80, 60, 40, 20, 0]
                      .map((label) => Text(
                            '$label',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ))
                      .toList(),
                ),
                const SizedBox(width: 8),
                // The Chart Area
                Expanded(
                  child: Stack(
                    children: [
                      // Grid lines (Vertical Axis)
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.grey, width: 1),
                            bottom: BorderSide(color: Colors.grey, width: 1),
                          ),
                        ),
                      ),
                      // The Bezier Curve
                      Positioned.fill(
                        child: CustomPaint(
                          painter: CurvePainter(
                            data: days.values.map((e) => e.toDouble()).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X-Axis Labels (Sun - Sat)
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.keys.map((day) => Text(
                day,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  final List<double> data;
  CurvePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = AppColors.primaryBlue // Blue curve from your UI
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2196F3).withOpacity(0.4),
          const Color(0xFF2196F3).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final double stepX = size.width / (data.length - 1);
    const double maxY = 100.0; // Matching the Y-axis label max

    // Starting point
    path.moveTo(0, size.height - (data[0] / maxY * size.height));

    for (int i = 0; i < data.length - 1; i++) {
      double x1 = i * stepX;
      double y1 = size.height - (data[i] / maxY * size.height);
      double x2 = (i + 1) * stepX;
      double y2 = size.height - (data[i + 1] / maxY * size.height);

      // Smooth Curve Logic
      path.cubicTo(
        (x1 + x2) / 2, y1,
        (x1 + x2) / 2, y2,
        x2, y2,
      );
    }

    // Gradient Area
    Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}