import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../painting/action_painter.dart';
import '../services/flood_fill_service.dart';
import '../state/drawing_provider.dart';

/// Die Malfläche. Zeichnet Vorlagen-Outline, Striche und Füllungen.
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
        final scale = (vb.width <= 0 || vb.height <= 0)
            ? 1.0
            : math.min(
                canvasSize.width / vb.width, canvasSize.height / vb.height);
        final offset = Offset(
          (canvasSize.width - vb.width * scale) / 2,
          (canvasSize.height - vb.height * scale) / 2,
        );

        Offset toSvg(Offset screenPoint) => (screenPoint - offset) / scale;

        // Sichtbarer Canvas-Bereich in SVG-Koordinaten (für Flood-Fill).
        final visibleRegion = Rect.fromPoints(
          toSvg(Offset.zero),
          toSvg(Offset(canvasSize.width, canvasSize.height)),
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _handleTap(
            context,
            toSvg(d.localPosition),
            visibleRegion,
            2 / scale,
          ),
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
          onPanCancel: () => provider.endStroke(),
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

  /// Tap: Farbeimer füllt, alle anderen Werkzeuge setzen einen Punkt.
  void _handleTap(BuildContext context, Offset svgPoint, Rect visibleRegion,
      double outlineWidth) {
    final provider = context.read<DrawingProvider>();

    if (provider.currentTool == Tool.fill) {
      _handleFillTap(provider, svgPoint, visibleRegion, outlineWidth);
      return;
    }

    // Tap mit Pinsel/Radierer: einzelner Punkt (wie bisher über Pan).
    if (provider.mode == DrawMode.fields &&
        provider.currentTool == Tool.brush) {
      provider.selectFieldAt(svgPoint);
    }
    provider.startStroke(svgPoint);
    provider.endStroke();
  }

  Future<void> _handleFillTap(DrawingProvider provider, Offset svgPoint,
      Rect visibleRegion, double outlineWidth) async {
    // Feld-Modus mit Vorlage: das getippte Feld komplett füllen.
    if (provider.mode == DrawMode.fields && provider.template != null) {
      if (provider.selectFieldAt(svgPoint)) {
        provider.fillSelectedField();
      }
      return;
    }

    // Frei-Modus: Flood-Fill an der getippten Position.
    if (provider.isFilling) return;
    provider.beginFill();
    try {
      final fill = await FloodFillService.createFill(
        actions: provider.actions,
        template: provider.template,
        region: visibleRegion,
        seed: svgPoint,
        color: provider.currentColor,
        pattern: provider.fillPattern,
        outlineWidth: outlineWidth,
      );
      if (fill != null) provider.addRasterFill(fill);
    } finally {
      provider.endFill();
    }
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

    ActionPainter.paintAll(
      canvas,
      actions: provider.actions,
      activeStroke: provider.activeStroke,
      template: template,
      outlineWidth: 2 / scale,
    );

    // Auswahl-Markierung über allem
    if (template != null) {
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

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
