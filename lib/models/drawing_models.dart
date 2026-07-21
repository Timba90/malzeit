import 'dart:ui';

/// Ein einzelner Punkt eines Strichs.
///
/// Nur Position und Farbe sind pro Punkt nötig — alle anderen Eigenschaften
/// (Breite, Radierer, Feld, Pinsel-Typ) gehören zum [DrawStroke].
class DrawPoint {
  final Offset position;
  final Color color;

  const DrawPoint({required this.position, required this.color});
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

/// Füll-Muster für das Farbeimer-Werkzeug (programmiert, keine Bilder).
enum FillPattern {
  dots,
  stripes,
  stars,
  hearts,
  checker,
  scales,
  rainbow,
  flowers,
}

/// Basisklasse für alles, was auf der Leinwand landet (Undo-Historie).
abstract class DrawAction {
  const DrawAction();
}

/// Ein kompletter Strich, bestehend aus Punkten.
class DrawStroke extends DrawAction {
  final List<DrawPoint> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  /// Identität des Felds, in dem gemalt wurde (null = Freier Modus).
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

/// Füllung eines kompletten SVG-Felds (Farbeimer im Feld-Modus).
class FieldFill extends DrawAction {
  final String fieldId;
  final Color color;

  /// null = einfarbige Füllung.
  final FillPattern? pattern;

  const FieldFill({
    required this.fieldId,
    required this.color,
    this.pattern,
  });
}

/// Ergebnis eines Flood-Fills im Frei-Modus.
///
/// [mask] ist ein Raster-Bild (weiß = gefüllt, transparent = nicht gefüllt),
/// das beim Zeichnen mit Farbe bzw. Muster gefüllt und über [rect]
/// (SVG-Koordinaten) gelegt wird.
class RasterFill extends DrawAction {
  final Image mask;
  final Rect rect;
  final Color color;

  /// null = einfarbige Füllung.
  final FillPattern? pattern;

  const RasterFill({
    required this.mask,
    required this.rect,
    required this.color,
    this.pattern,
  });

  /// Gibt den Bildspeicher der Maske frei (nach Undo/Leeren).
  void dispose() => mask.dispose();
}
