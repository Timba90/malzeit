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

/// Pinsel-Typ — bestimmt wie der Strich gerendert wird.
enum BrushType {
  /// Normaler Pinsel (durchgezogene Linie).
  solid,

  /// Sternen-Pinsel — hinterlässt eine Spur aus kleinen Sternen.
  star,

  /// Glitzer-Pinsel — hinterlässt funkelnde Punkte.
  glitter,

  /// Regenbogen-Pinsel — Farbe wechselt entlang des Strichs.
  rainbow,
}

/// Ein kompletter Strich, bestehend aus Punkten.
class DrawStroke {
  final List<DrawPoint> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;
  final String? fieldId;
  final BrushType brushType;

  DrawStroke({
    List<DrawPoint>? points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
    this.fieldId,
    this.brushType = BrushType.solid,
  }) : points = points ?? [];
}
