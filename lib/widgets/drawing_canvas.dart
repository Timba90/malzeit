import 'dart:math' show cos, sin, pi;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/decoration_models.dart' as deco;
import '../models/drawing_models.dart';
import '../state/drawing_provider.dart';

/// Die Malfläche. Zeichnet Vorlagen-Outline, Striche und Dekorationen.
/// Im Feld-Modus werden alle Striche auf das ausgewählte Feld beschnitten.
class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DrawingProvider>();
    final template = provider.template;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final vb = template?.viewBox ?? const Size(300, 300);
        final scale = (canvasSize.width / vb.width).clamp(0.0, double.infinity) <
                canvasSize.height / vb.height
            ? canvasSize.width / vb.width
            : canvasSize.height / vb.height;
        final offset = Offset(
          (canvasSize.width - vb.width * scale) / 2,
          (canvasSize.height - vb.height * scale) / 2,
        );

        Offset toSvg(Offset screenPoint) => (screenPoint - offset) / scale;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            final svgPoint = toSvg(d.localPosition);
            if (provider.mode == DrawMode.fields &&
                provider.currentTool == Tool.brush) {
              provider.selectFieldAt(svgPoint);
            }
            provider.startStroke(svgPoint);
          },
          onPanUpdate: (d) => provider.extendStroke(toSvg(d.localPosition)),
          onPanEnd: (_) => provider.endStroke(),
          child: Container(
            color: Colors.white,
            child: CustomPaint(
              size: canvasSize,
              painter: _DrawingPainter(
                provider: provider,
                scale: scale,
                offset: offset,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final DrawingProvider provider;
  final double scale;
  final Offset offset;

  _DrawingPainter({
    required this.provider,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final template = provider.template;

    // 1) Abgeschlossene Striche
    for (final stroke in provider.strokes) {
      _paintStroke(canvas, stroke, template);
    }
    // 2) Aktiver Strich
    final active = provider.activeStroke;
    if (active != null) {
      _paintStroke(canvas, active, template);
    }

    // 3) Dekorationen (alten Stempel — wird kaum noch genutzt)
    for (final d in provider.decorations) {
      _paintDecoration(canvas, d, template);
    }

    // 4) Vorlagen-Outline über allem
    if (template != null) {
      _paintOutline(canvas, template);
      final sel = provider.selectedField;
      if (provider.mode == DrawMode.fields && sel != null) {
        final highlight = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 / scale
          ..color = const Color(0xFF1E88E5);
        canvas.drawPath(sel.path, highlight);
      }
    }

    canvas.restore();
  }

  // ===================== Stroke Rendering =====================

  void _paintStroke(Canvas canvas, DrawStroke stroke, template) {
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

  void _withFieldClip(Canvas canvas, DrawStroke stroke, template, VoidCallback draw) {
    final fieldId = stroke.fieldId;
    if (fieldId != null && template != null) {
      final field = template.fields
          .where((f) => f.id == fieldId)
          .cast<dynamic>()
          .firstOrNull;
      if (field != null) {
        canvas.save();
        canvas.clipPath(field.path as Path);
        draw();
        canvas.restore();
        return;
      }
    }
    draw();
  }

  // --- Solid (normaler Pinsel + Radierer) ---
  void _paintSolidStroke(Canvas canvas, DrawStroke stroke, template) {
    _withFieldClip(canvas, stroke, template, () {
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke
        ..color = stroke.isEraser ? Colors.white : stroke.color;

      final pts = stroke.points;
      if (pts.length == 1) {
        canvas.drawCircle(pts.first.position, stroke.strokeWidth / 2,
            Paint()..color = stroke.isEraser ? Colors.white : stroke.color);
        return;
      }
      final path = Path()..moveTo(pts.first.position.dx, pts.first.position.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].position.dx, pts[i].position.dy);
      }
      canvas.drawPath(path, paint);
    });
  }

  // --- Regenbogen-Pinsel: Segment-für-Segment mit Punkt-Farbe ---
  void _paintRainbowStroke(Canvas canvas, DrawStroke stroke, template) {
    _withFieldClip(canvas, stroke, template, () {
      final pts = stroke.points;
      for (var i = 1; i < pts.length; i++) {
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke.strokeWidth
          ..style = PaintingStyle.stroke
          ..color = pts[i].color;
        canvas.drawLine(pts[i - 1].position, pts[i].position, paint);
      }
      // Ersten Punkt als Kreis zeichnen falls nur 1 Punkt
      if (pts.length == 1) {
        canvas.drawCircle(pts.first.position, stroke.strokeWidth / 2,
            Paint()..color = pts.first.color);
      }
    });
  }

  // --- Sternen-Pinsel: entlang des Pfads kleine Sterne verteilen ---
  void _paintStarTrail(Canvas canvas, DrawStroke stroke, template) {
    _withFieldClip(canvas, stroke, template, () {
      final pts = stroke.points;
      // Sterne in regelmäßigen Abständen platzieren
      final spacing = stroke.strokeWidth * 1.5;
      var accumulated = spacing; // sofort ersten Stern setzen
      for (var i = 1; i < pts.length; i++) {
        final prev = pts[i - 1].position;
        final cur = pts[i].position;
        final dist = (cur - prev).distance;
        if (dist == 0) continue;
        final dir = (cur - prev) / dist;
        var pos = prev;
        while (accumulated <= dist) {
          pos = prev + dir * accumulated;
          _drawStarShape(canvas, pos, stroke.strokeWidth * 0.9, stroke.color);
          accumulated += spacing;
        }
        accumulated -= dist;
      }
      // Mindestens einen Stern malen (Tap)
      if (pts.isNotEmpty) {
        _drawStarShape(canvas, pts.first.position, stroke.strokeWidth * 0.9, stroke.color);
      }
    });
  }

  // --- Glitzer-Pinsel: bunte kleine Punkte entlang des Pfads ---
  void _paintGlitterTrail(Canvas canvas, DrawStroke stroke, template) {
    _withFieldClip(canvas, stroke, template, () {
      final pts = stroke.points;
      final glitterColors = [
        const Color(0xFFFFD54F),
        const Color(0xFFFF8A80),
        const Color(0xFF80D8FF),
        const Color(0xFFB9F6CA),
        const Color(0xFFE1BEE7),
      ];
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
    });
  }

  // ===================== Shape Helpers =====================

  void _drawStarShape(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    const spikes = 5;
    final outer = size / 2;
    final inner = outer * 0.45;
    for (var i = 0; i < spikes * 2; i++) {
      final r = i.isEven ? outer : inner;
      final angle = (i * pi / spikes) - pi / 2;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintDecoration(Canvas canvas, deco.Decoration d, template) {
    void draw() {
      switch (d.type) {
        case deco.DecorationType.star:
          _drawStarShape(canvas, d.position, d.size, d.color);
          break;
        case deco.DecorationType.glitter:
          // alte Stempel-Dekoration — als kleine Punkte
          for (var i = 0; i < 6; i++) {
            final a = i * 1.04;
            canvas.drawCircle(
              d.position + Offset(cos(a) * 6, sin(a) * 6),
              2,
              Paint()..color = d.color,
            );
          }
          break;
      }
    }

    final fieldId = d.fieldId;
    if (fieldId != null && template != null) {
      final field = template.fields
          .where((f) => f.id == fieldId)
          .cast<dynamic>()
          .firstOrNull;
      if (field != null) {
        canvas.save();
        canvas.clipPath(field.path as Path);
        draw();
        canvas.restore();
        return;
      }
    }
    draw();
  }

  void _paintOutline(Canvas canvas, template) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 / scale
      ..color = const Color(0xFF424242);
    for (final field in template.fields) {
      canvas.drawPath(field.path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
