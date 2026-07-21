import 'package:flutter/material.dart';

import '../models/drawing_models.dart';
import '../models/svg_template.dart';
import 'pattern_painter.dart';

/// Gemeinsames Rendering aller [DrawAction]s.
///
/// Wird sowohl vom Live-Canvas ([CustomPainter]) als auch vom
/// Flood-Fill-Renderer (Raster-Abbild für die Füll-Berechnung) genutzt,
/// damit beide exakt dasselbe Bild sehen.
class ActionPainter {
  /// Malt alle Aktionen, den aktiven Strich und die Vorlagen-Outline.
  /// Das Canvas muss bereits in SVG-Koordinaten transformiert sein.
  static void paintAll(
    Canvas canvas, {
    required List<DrawAction> actions,
    DrawStroke? activeStroke,
    SvgTemplate? template,
    required double outlineWidth,
  }) {
    for (final action in actions) {
      paintAction(canvas, action, template);
    }
    if (activeStroke != null) {
      paintStroke(canvas, activeStroke, template);
    }
    if (template != null) {
      paintOutline(canvas, template, outlineWidth);
    }
  }

  static void paintAction(
      Canvas canvas, DrawAction action, SvgTemplate? template) {
    if (action is DrawStroke) {
      paintStroke(canvas, action, template);
    } else if (action is FieldFill) {
      _paintFieldFill(canvas, action, template);
    } else if (action is RasterFill) {
      _paintRasterFill(canvas, action);
    }
  }

  static void paintOutline(
      Canvas canvas, SvgTemplate template, double outlineWidth) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth
      ..color = const Color(0xFF424242);
    for (final field in template.fields) {
      canvas.drawPath(field.path, paint);
    }
  }

  // ===================== Füllungen =====================

  static void _paintFieldFill(
      Canvas canvas, FieldFill fill, SvgTemplate? template) {
    final field = _findField(template, fill.fieldId);
    if (field == null) return;
    canvas.save();
    canvas.clipPath(field.path);
    final bounds = field.path.getBounds();
    if (fill.pattern != null) {
      paintPattern(canvas, bounds, fill.pattern!, fill.color);
    } else {
      canvas.drawRect(bounds, Paint()..color = fill.color);
    }
    canvas.restore();
  }

  static void _paintRasterFill(Canvas canvas, RasterFill fill) {
    // Füll-Inhalt malen und anschließend mit der Masken-Alpha beschneiden.
    canvas.saveLayer(fill.rect, Paint());
    if (fill.pattern != null) {
      paintPattern(canvas, fill.rect, fill.pattern!, fill.color);
    } else {
      canvas.drawRect(fill.rect, Paint()..color = fill.color);
    }
    canvas.drawImageRect(
      fill.mask,
      Rect.fromLTWH(
          0, 0, fill.mask.width.toDouble(), fill.mask.height.toDouble()),
      fill.rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..filterQuality = FilterQuality.low,
    );
    canvas.restore();
  }

  static SvgField? _findField(SvgTemplate? template, String fieldId) {
    if (template == null) return null;
    for (final f in template.fields) {
      if (f.id == fieldId) return f;
    }
    return null;
  }

  // ===================== Stroke Rendering =====================

  static void paintStroke(
      Canvas canvas, DrawStroke stroke, SvgTemplate? template) {
    if (stroke.points.isEmpty) return;

    switch (stroke.brushType) {
      case BrushType.solid:
        _paintSolidStroke(canvas, stroke, template);
        break;
      case BrushType.star:
        _paintStarTrail(canvas, stroke, template);
        break;
      case BrushType.glitter:
        _paintGlitterTrail(canvas, stroke, template);
        break;
      case BrushType.rainbow:
        _paintRainbowStroke(canvas, stroke, template);
        break;
    }
  }

  static void _withFieldClip(Canvas canvas, DrawStroke stroke,
      SvgTemplate? template, VoidCallback draw) {
    final fieldId = stroke.fieldId;
    if (fieldId != null && template != null) {
      final field = _findField(template, fieldId);
      if (field != null) {
        canvas.save();
        canvas.clipPath(field.path);
        draw();
        canvas.restore();
        return;
      }
    }
    draw();
  }

  // --- Solid (normaler Pinsel + Radierer) ---
  static void _paintSolidStroke(
      Canvas canvas, DrawStroke stroke, SvgTemplate? template) {
    _withFieldClip(canvas, stroke, template, () {
      final color = stroke.isEraser ? Colors.white : stroke.color;
      final pts = stroke.points;
      if (pts.length == 1) {
        canvas.drawCircle(pts.first.position, stroke.strokeWidth / 2,
            Paint()..color = color);
        return;
      }
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke
        ..color = color;
      final path = Path()..moveTo(pts.first.position.dx, pts.first.position.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].position.dx, pts[i].position.dy);
      }
      canvas.drawPath(path, paint);
    });
  }

  // --- Regenbogen-Pinsel: Segment-für-Segment mit Punkt-Farbe ---
  static void _paintRainbowStroke(
      Canvas canvas, DrawStroke stroke, SvgTemplate? template) {
    _withFieldClip(canvas, stroke, template, () {
      final pts = stroke.points;
      if (pts.length == 1) {
        canvas.drawCircle(pts.first.position, stroke.strokeWidth / 2,
            Paint()..color = pts.first.color);
        return;
      }
      for (var i = 1; i < pts.length; i++) {
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke.strokeWidth
          ..style = PaintingStyle.stroke
          ..color = pts[i].color;
        canvas.drawLine(pts[i - 1].position, pts[i].position, paint);
      }
    });
  }

  // --- Sternen-Pinsel: entlang des Pfads kleine Sterne verteilen ---
  static void _paintStarTrail(
      Canvas canvas, DrawStroke stroke, SvgTemplate? template) {
    _withFieldClip(canvas, stroke, template, () {
      final paint = Paint()..color = stroke.color;
      final pts = stroke.points;
      final spacing = stroke.strokeWidth * 1.5;
      var accumulated = spacing; // sofort ersten Stern setzen
      for (var i = 1; i < pts.length; i++) {
        final prev = pts[i - 1].position;
        final cur = pts[i].position;
        final dist = (cur - prev).distance;
        if (dist == 0) continue;
        final dir = (cur - prev) / dist;
        while (accumulated <= dist) {
          final pos = prev + dir * accumulated;
          canvas.drawPath(starPath(pos, stroke.strokeWidth * 0.9), paint);
          accumulated += spacing;
        }
        accumulated -= dist;
      }
      // Mindestens einen Stern malen (Tap)
      canvas.drawPath(
          starPath(pts.first.position, stroke.strokeWidth * 0.9), paint);
    });
  }

  // --- Glitzer-Pinsel: bunte kleine Punkte entlang des Pfads ---
  static void _paintGlitterTrail(
      Canvas canvas, DrawStroke stroke, SvgTemplate? template) {
    _withFieldClip(canvas, stroke, template, () {
      const glitterColors = [
        Color(0xFFFFD54F),
        Color(0xFFFF8A80),
        Color(0xFF80D8FF),
        Color(0xFFB9F6CA),
        Color(0xFFE1BEE7),
      ];
      final pts = stroke.points;
      final spacing = stroke.strokeWidth * 0.8;
      var accumulated = 0.0;
      var colorIdx = 0;
      for (var i = 1; i < pts.length; i++) {
        final prev = pts[i - 1].position;
        final cur = pts[i].position;
        final dist = (cur - prev).distance;
        if (dist == 0) continue;
        final dir = (cur - prev) / dist;
        while (accumulated <= dist) {
          final pos = prev + dir * accumulated;
          final jitterX = (accumulated * 7.3 % 1.0 - 0.5) * stroke.strokeWidth;
          final jitterY = (accumulated * 3.7 % 1.0 - 0.5) * stroke.strokeWidth;
          canvas.drawCircle(
            pos + Offset(jitterX, jitterY),
            stroke.strokeWidth * 0.25,
            Paint()..color = glitterColors[colorIdx % glitterColors.length],
          );
          colorIdx++;
          accumulated += spacing;
        }
        accumulated -= dist;
      }
      // Tap ohne Bewegung: einen Glitzerpunkt setzen
      if (pts.length == 1) {
        canvas.drawCircle(pts.first.position, stroke.strokeWidth * 0.25,
            Paint()..color = glitterColors.first);
      }
    });
  }
}
