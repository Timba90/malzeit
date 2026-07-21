import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/drawing_models.dart';

/// Malt ein [FillPattern] flächendeckend in [rect].
///
/// Der Aufrufer muss das Canvas vorher auf die Zielform clippen
/// (Feld-Pfad, Masken-Layer oder Vorschau-Kreis).
/// [tile] steuert die Kachelgröße; ohne Angabe wird sie aus [rect] abgeleitet.
void paintPattern(
  Canvas canvas,
  Rect rect,
  FillPattern pattern,
  Color color, {
  double? tile,
}) {
  final t = tile ?? (math.min(rect.width, rect.height) / 5).clamp(10.0, 30.0);

  // Heller Hintergrund in der Musterfarbe, damit die Fläche gefüllt wirkt.
  final bg = pattern == FillPattern.rainbow
      ? Colors.white
      : Color.lerp(Colors.white, color, 0.22)!;
  canvas.drawRect(rect, Paint()..color = bg);

  switch (pattern) {
    case FillPattern.dots:
      _paintDots(canvas, rect, color, t);
      break;
    case FillPattern.stripes:
      _paintStripes(canvas, rect, color, t);
      break;
    case FillPattern.stars:
      _paintStars(canvas, rect, color, t);
      break;
    case FillPattern.hearts:
      _paintHearts(canvas, rect, color, t);
      break;
    case FillPattern.checker:
      _paintChecker(canvas, rect, color, t);
      break;
    case FillPattern.scales:
      _paintScales(canvas, rect, color, t);
      break;
    case FillPattern.rainbow:
      _paintRainbow(canvas, rect, t);
      break;
    case FillPattern.flowers:
      _paintFlowers(canvas, rect, color, t);
      break;
  }
}

/// Kindgerechte deutsche Namen der Muster (für Tooltips/Labels).
String patternLabel(FillPattern pattern) {
  switch (pattern) {
    case FillPattern.dots:
      return 'Punkte';
    case FillPattern.stripes:
      return 'Streifen';
    case FillPattern.stars:
      return 'Sterne';
    case FillPattern.hearts:
      return 'Herzen';
    case FillPattern.checker:
      return 'Karo';
    case FillPattern.scales:
      return 'Schuppen';
    case FillPattern.rainbow:
      return 'Regenbogen';
    case FillPattern.flowers:
      return 'Blumen';
  }
}

// ===================== Einzelne Muster =====================

void _paintDots(Canvas canvas, Rect rect, Color color, double t) {
  final paint = Paint()..color = color;
  var row = 0;
  for (var y = rect.top + t / 2; y < rect.bottom + t; y += t * 0.9) {
    final shift = row.isOdd ? t / 2 : 0.0;
    for (var x = rect.left + t / 2 + shift; x < rect.right + t; x += t) {
      canvas.drawCircle(Offset(x, y), t * 0.26, paint);
    }
    row++;
  }
}

void _paintStripes(Canvas canvas, Rect rect, Color color, double t) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = t * 0.45
    ..strokeCap = StrokeCap.round;
  // Diagonale Streifen von links-unten nach rechts-oben.
  for (var d = -rect.height; d < rect.width + rect.height; d += t * 1.2) {
    canvas.drawLine(
      Offset(rect.left + d, rect.bottom + t),
      Offset(rect.left + d + rect.height + 2 * t, rect.top - t),
      paint,
    );
  }
}

void _paintStars(Canvas canvas, Rect rect, Color color, double t) {
  final paint = Paint()..color = color;
  var row = 0;
  for (var y = rect.top + t / 2; y < rect.bottom + t; y += t) {
    final shift = row.isOdd ? t / 2 : 0.0;
    for (var x = rect.left + t / 2 + shift; x < rect.right + t; x += t) {
      canvas.drawPath(starPath(Offset(x, y), t * 0.7), paint);
    }
    row++;
  }
}

void _paintHearts(Canvas canvas, Rect rect, Color color, double t) {
  final paint = Paint()..color = color;
  var row = 0;
  for (var y = rect.top + t / 2; y < rect.bottom + t; y += t) {
    final shift = row.isOdd ? t / 2 : 0.0;
    for (var x = rect.left + t / 2 + shift; x < rect.right + t; x += t) {
      canvas.drawPath(_heartPath(Offset(x, y), t * 0.62), paint);
    }
    row++;
  }
}

void _paintChecker(Canvas canvas, Rect rect, Color color, double t) {
  final paint = Paint()..color = color;
  var row = 0;
  for (var y = rect.top; y < rect.bottom; y += t) {
    var col = 0;
    for (var x = rect.left; x < rect.right; x += t) {
      if ((row + col).isEven) {
        canvas.drawRect(Rect.fromLTWH(x, y, t, t), paint);
      }
      col++;
    }
    row++;
  }
}

void _paintScales(Canvas canvas, Rect rect, Color color, double t) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = t * 0.14;
  // Überlappende Halbkreis-Reihen wie Fischschuppen.
  var row = 0;
  for (var y = rect.top; y < rect.bottom + t; y += t * 0.55) {
    final shift = row.isOdd ? t / 2 : 0.0;
    for (var x = rect.left - t + shift; x < rect.right + t; x += t) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x, y), radius: t / 2),
        0,
        math.pi,
        false,
        paint,
      );
    }
    row++;
  }
}

void _paintRainbow(Canvas canvas, Rect rect, double t) {
  const colors = [
    Color(0xFFF44336), // Rot
    Color(0xFFFF9800), // Orange
    Color(0xFFFFEB3B), // Gelb
    Color(0xFF4CAF50), // Grün
    Color(0xFF2196F3), // Blau
    Color(0xFF9C27B0), // Lila
  ];
  final stripe = t * 0.55;
  var i = 0;
  for (var y = rect.top; y < rect.bottom; y += stripe) {
    canvas.drawRect(
      Rect.fromLTWH(rect.left, y, rect.width, stripe + 0.5),
      Paint()..color = colors[i % colors.length],
    );
    i++;
  }
}

void _paintFlowers(Canvas canvas, Rect rect, Color color, double t) {
  final petal = Paint()..color = color;
  final center = Paint()..color = const Color(0xFFFFC107);
  var row = 0;
  for (var y = rect.top + t / 2; y < rect.bottom + t; y += t * 1.1) {
    final shift = row.isOdd ? t / 2 : 0.0;
    for (var x = rect.left + t / 2 + shift; x < rect.right + t; x += t * 1.1) {
      final c = Offset(x, y);
      for (var p = 0; p < 5; p++) {
        final angle = p * 2 * math.pi / 5 - math.pi / 2;
        canvas.drawCircle(
          c + Offset(math.cos(angle), math.sin(angle)) * t * 0.24,
          t * 0.17,
          petal,
        );
      }
      canvas.drawCircle(c, t * 0.13, center);
    }
    row++;
  }
}

// ===================== Form-Helfer =====================

/// Fünfzackiger Stern um [center] mit Gesamtgröße [size].
Path starPath(Offset center, double size) {
  final path = Path();
  const spikes = 5;
  final outer = size / 2;
  final inner = outer * 0.45;
  for (var i = 0; i < spikes * 2; i++) {
    final r = i.isEven ? outer : inner;
    final angle = (i * math.pi / spikes) - math.pi / 2;
    final x = center.dx + r * math.cos(angle);
    final y = center.dy + r * math.sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

Path _heartPath(Offset center, double size) {
  final s = size / 2;
  final path = Path()
    ..moveTo(center.dx, center.dy + s * 0.9)
    ..cubicTo(center.dx - s * 1.5, center.dy - s * 0.2, center.dx - s * 0.7,
        center.dy - s * 1.2, center.dx, center.dy - s * 0.35)
    ..cubicTo(center.dx + s * 0.7, center.dy - s * 1.2, center.dx + s * 1.5,
        center.dy - s * 0.2, center.dx, center.dy + s * 0.9)
    ..close();
  return path;
}
