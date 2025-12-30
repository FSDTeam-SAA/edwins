import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/app_style.dart';

class ProgressRadarChart extends StatelessWidget {
  final Map<String, int> skills;

  const ProgressRadarChart({
    super.key,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    final dataEntries = skills.values
        .map((e) => RadarEntry(value: e.toDouble()))
        .toList();

    return AspectRatio(
      aspectRatio: 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// Dashed inner grid rings
          Positioned.fill(
            child: CustomPaint(
              painter: DashedRadarGridPainter(
                sides: skills.length,
                ticks: 05,
                dashLength: 5,
                gapLength: 1,
                strokeColor: Colors.grey.withOpacity(0.35),
              ),
            ),
          ),

          /// Main FLChart Radar
          RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              radarBackgroundColor: Colors.transparent,
              gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.3), width: 2),

              /// Outer border (solid)
              radarBorderData: BorderSide(
                color: Colors.transparent
              ),

              /// Hide built-in grid lines and axes
              tickBorderData: const BorderSide(color: Colors.transparent),
              borderData: FlBorderData(show: false),

              // tickCount:,
              ticksTextStyle: const TextStyle(color: Colors.transparent),

              /// Labels (skill name + %)
              getTitle: (index, angle) {
                final key = skills.keys.elementAt(index);
                final value = skills.values.elementAt(index);

                return RadarChartTitle(
                  text: "$key\n$value%",
                  angle: 0,
                  positionPercentageOffset: 0.13,
                );
              },
              titleTextStyle: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),

              /// Filled polygon data
              dataSets: [
                RadarDataSet(
                  dataEntries: dataEntries,
                  fillColor: AppColors.chartFill,
                  borderColor: AppColors.chartBorder,
                  entryRadius: 0, // No dots at corners
                  borderWidth: 2,
                ),
              ],
            ),
            swapAnimationDuration: const Duration(milliseconds: 400),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dashed inner polygon rings ONLY
class DashedRadarGridPainter extends CustomPainter {
  final int sides;
  final int ticks;
  final double dashLength;
  final double gapLength;
  final Color strokeColor;

  DashedRadarGridPainter({
    required this.sides,
    required this.ticks,
    required this.dashLength,
    required this.gapLength,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int t = 1; t < ticks; t++) {
      final radius = (maxRadius / ticks) * t;
      final path = Path();

      for (int i = 0; i <= sides; i++) {
        final angle = (2 * pi / sides) * i;
        final dx = center.dx + radius * cos(angle);
        final dy = center.dy + radius * sin(angle);

        if (i == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }

      /// Draw dashed paths
      for (final metric in path.computeMetrics()) {
        double distance = 0;
        while (distance < metric.length) {
          final next = distance + dashLength;
          canvas.drawPath(
            metric.extractPath(distance, next),
            paint,
          );
          distance = next + gapLength;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}