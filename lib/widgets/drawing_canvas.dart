import 'dart:math' show cos, sin;

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

        // Skalierung SVG-Koordinaten -> Bildschirm (proportional, zentriert)
        final vb = template?.viewBox ?? const Size(300, 300);
        final scale =
            (canvasSize.width / vb.width).clamp(0.0, double.infinity) <
                    canvasSize.height / vb.height
                ? canvasSize.width / vb.width
                : canvasSize.height / vb.height;
        final offset = Offset(
          (canvasSize.width - vb.width * scale) / 2,
          (canvasSize.height - vb.height * scale) / 2,
        );

        Offset toSvg(Offset screenPoint) =>
            (screenPoint - offset) / scale;

        return GestureDetector(
          onPanStart: (d) {
            final svgPoint = toSvg(d.localPosition);
            if (provider.mode == DrawMode.fields &&
                (provider.currentTool == Tool.brush ||
                    provider.currentTool == Tool.eraser)) {
              // Im Feld-Modus wählt ein Tap auf ein anderes Feld dieses aus
              // und startet dort den Strich.
              provider.selectFieldAt(svgPoint);
            }
            provider.startStroke(svgPoint);
          },
          onPanUpdate: (d) => provider.extendStroke(toSvg(d.localPosition)),
          onPanEnd: (_) => provider.endStroke(),
          onTapDown: (d) {
            final svgPoint = toSvg(d.localPosition);
            if (provider.currentTool == Tool.star ||
                provider.currentTool == Tool.glitter) {
              if (provider.mode == DrawMode.fields) {
                provider.selectFieldAt(svgPoint);
              }
              provider.addDecoration(svgPoint);
            } else if (provider.mode == DrawMode.fields) {
              provider.selectFieldAt(svgPoint);
            }
          },
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

    // 3) Dekorationen (dauerhaft sichtbar)
    for (final d in provider.decorations) {
      _paintDecoration(canvas, d, template);
    }

    // 4) Vorlagen-Outline über allem
    if (template != null) {
      _paintOutline(canvas, template);
      // Ausgewähltes Feld hervorheben
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

  void _paintStroke(Canvas canvas, DrawStroke stroke, template) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke;

    if (stroke.isEraser) {
      paint.color = Colors.white;
    } else {
      paint.color = stroke.color;
    }

    void drawAll() {
      final pts = stroke.points;
      if (pts.length == 1) {
        canvas.drawCircle(
            pts.first.position, stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        return;
      }
      final path = Path()..moveTo(pts.first.position.dx, pts.first.position.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].position.dx, pts[i].position.dy);
      }
      canvas.drawPath(path, paint);
    }

    // Im Feld-Modus: auf das Feld beschränken, in dem gemalt wurde
    final fieldId = stroke.fieldId;
    if (fieldId != null && template != null) {
      final field = template.fields
          .where((f) => f.id == fieldId)
          .cast<dynamic>()
          .firstOrNull;
      if (field != null) {
        canvas.save();
        canvas.clipPath(field.path as Path);
        drawAll();
        canvas.restore();
        return;
      }
    }
    drawAll();
  }

  void _paintDecoration(Canvas canvas, deco.Decoration d, template) {
    void draw() {
      switch (d.type) {
        case deco.DecorationType.star:
          _drawStar(canvas, d.position, d.size, d.color);
          break;
        case deco.DecorationType.glitter:
          _drawGlitter(canvas, d.position, d.size);
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

  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    const spikes = 5;
    final outer = size / 2;
    final inner = outer * 0.45;
    for (var i = 0; i < spikes * 2; i++) {
      final r = i.isEven ? outer : inner;
      final angle = (i * 3.14159265 / spikes) - 3.14159265 / 2;
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

  void _drawGlitter(Canvas canvas, Offset center, double size) {
    final rnd = [0.2, 0.7, 0.4, 0.9, 0.5, 0.1, 0.8, 0.3];
    final colors = [
      const Color(0xFFFFD54F),
      const Color(0xFFFF8A80),
      const Color(0xFF80D8FF),
      const Color(0xFFB9F6CA),
    ];
    for (var i = 0; i < 8; i++) {
      final angle = rnd[i] * 6.283;
      final dist = size * 0.5 * rnd[(i + 3) % 8];
      final pos = center + Offset(cos(angle) * dist, sin(angle) * dist);
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 2.2 + rnd[(i + 5) % 8] * 2.5, paint);
    }
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
