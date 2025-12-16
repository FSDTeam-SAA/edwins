import 'dart:math';

import 'package:flutter/material.dart';

class LineValue {
  final String label;
  final double value;
  LineValue({required this.label, required this.value});
}

class PentagonPainter extends CustomPainter {
  final List<LineValue> lineValues; // 5 Objekte mit label + value

  PentagonPainter({required this.lineValues}) : assert(lineValues.length == 5);

  @override
  void paint(Canvas canvas, Size size) {
    final paintPentagon = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final paintCenterLines = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final paintPoints = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    final paintPolygonFill = Paint()
      ..color = Colors.orange.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final paintPolygonStroke = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Drei Radien
    final radii = [
      min(size.width, size.height) * 0.45,
      min(size.width, size.height) * 0.30,
      min(size.width, size.height) * 0.15,
    ];

    const int sides = 5;
    const double fullCircle = 2 * pi;
    final double angleStep = fullCircle / sides;
    double startAngle = -pi / 2;

    // Äußerste Punkte
    final List<Offset> outerCorners = [];

    for (int i = 0; i < sides; i++) {
      final x = center.dx + radii[0] * cos(startAngle + angleStep * i);
      final y = center.dy + radii[0] * sin(startAngle + angleStep * i);
      outerCorners.add(Offset(x, y));
    }

    // Gestrichelte Pentagons
    for (double radius in radii) {
      final List<Offset> points = [];

      for (int i = 0; i < sides; i++) {
        final x = center.dx + radius * cos(startAngle + angleStep * i);
        final y = center.dy + radius * sin(startAngle + angleStep * i);
        points.add(Offset(x, y));
      }

      for (int i = 0; i < points.length; i++) {
        _drawDashedLine(
            canvas, points[i], points[(i + 1) % points.length], paintPentagon);
      }
    }

    // Punkte anhand der Werte
    List<Offset> valuePoints = [];

    for (int i = 0; i < 5; i++) {
      final corner = outerCorners[i];

      // Linie zur Mitte
      canvas.drawLine(corner, center, paintCenterLines);

      // Punkt anhand value berechnen
      final t = lineValues[i].value.clamp(0.0, 1.0);

      final p = Offset(
        center.dx + (corner.dx - center.dx) * t,
        center.dy + (corner.dy - center.dy) * t,
      );

      valuePoints.add(p);
      canvas.drawCircle(p, 5, paintPoints);

      // 🔥 Text hinzufügen
      final textPainter = TextPainter(
        text: TextSpan(
          text: lineValues[i].label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Winkel dieser Achse
      final double angle = startAngle + angleStep * i;

      // Richtung der Linie (normiert)
      final Offset dir = Offset(cos(angle), sin(angle));

      // Punkt etwas außerhalb der Ecke
      final double textDistance = 10; // ggf. anpassen
      final Offset basePos = corner + dir * textDistance;

      late Offset drawPos;

// Text so ausrichten, dass er auf der Linie liegt:
// horizontal zentriert auf dem Punkt
      if (dir.dx > 0.1) {
        // rechte Seite → Text links ausrichten
        drawPos = Offset(
          basePos.dx, // linke Textkante auf Linie
          basePos.dy - textPainter.height / 2,
        );
      } else if (dir.dx < -0.1) {
        // linke Seite → Text rechts ausrichten
        drawPos = Offset(
          basePos.dx - textPainter.width, // rechte Textkante auf Linie
          basePos.dy - textPainter.height / 2,
        );
      } else {
        // oben/unten → horizontal zentrieren
        drawPos = Offset(
          basePos.dx - textPainter.width / 2,
          basePos.dy - textPainter.height / 2,
        );
      }

      textPainter.paint(canvas, drawPos);
    }

    // Polygon Fläche zeichnen
    final Path polygon = Path()..moveTo(valuePoints[0].dx, valuePoints[0].dy);
    for (int i = 1; i < valuePoints.length; i++) {
      polygon.lineTo(valuePoints[i].dx, valuePoints[i].dy);
    }
    polygon.close();

    canvas.drawPath(polygon, paintPolygonFill);
    canvas.drawPath(polygon, paintPolygonStroke);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      {double dashLength = 8, double gapLength = 5}) {
    final total = (end - start).distance;
    final direction = (end - start) / total;

    double distance = 0;
    while (distance < total) {
      final currentStart = start + direction * distance;
      final currentEnd = start + direction * min(distance + dashLength, total);
      canvas.drawLine(currentStart, currentEnd, paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant PentagonPainter oldDelegate) =>
      oldDelegate.lineValues != lineValues;
}
