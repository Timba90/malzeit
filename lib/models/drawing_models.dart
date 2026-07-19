import 'dart:ui';

/// Ein einzelner Farbpunkt (Strich-Segment) auf der Leinwand.
class DrawPoint {
  final Offset position;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  /// Identität des Felds, in dem dieser Punkt gemalt wurde (null = Freier Modus).
  final String? fieldId;

  const DrawPoint({
    required this.position,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
    this.fieldId,
  });
}

/// Ein kompletter Strich, bestehend aus Punkten.
class DrawStroke {
  final List<DrawPoint> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;
  final String? fieldId;

  DrawStroke({
    List<DrawPoint>? points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
    this.fieldId,
  }) : points = points ?? [];
}
