import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/drawing_models.dart';
import '../models/svg_template.dart';
import '../painting/action_painter.dart';

/// Flood-Fill für den Frei-Modus: rendert den aktuellen Leinwand-Zustand
/// als Rasterbild, füllt ab dem Tipp-Punkt alle zusammenhängenden Pixel
/// ähnlicher Farbe und liefert das Ergebnis als Alpha-Maske ([RasterFill]).
class FloodFillService {
  /// Maximale Kantenlänge des Raster-Abbilds (Balance Qualität/Tempo).
  static const double _maxRasterDim = 800;

  /// Farbtoleranz: quadrierte euklidische RGB-Distanz.
  static const int _toleranceSq = 32 * 32 * 3;

  /// Berechnet die Füllung. [region] und [seed] in SVG-Koordinaten,
  /// [outlineWidth] wie im Live-Canvas, damit Outlines als Grenzen wirken.
  /// Gibt null zurück, wenn außerhalb getippt wurde oder nichts zu füllen ist.
  static Future<RasterFill?> createFill({
    required List<DrawAction> actions,
    required SvgTemplate? template,
    required Rect region,
    required Offset seed,
    required Color color,
    required FillPattern? pattern,
    required double outlineWidth,
  }) async {
    if (region.isEmpty || !region.contains(seed)) return null;

    final scale = _maxRasterDim / math.max(region.width, region.height);
    final w = (region.width * scale).ceil();
    final h = (region.height * scale).ceil();

    // 1) Aktuellen Zustand exakt wie im Live-Canvas rastern.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);
    canvas.translate(-region.left, -region.top);
    canvas.drawRect(region, Paint()..color = Colors.white);
    ActionPainter.paintAll(
      canvas,
      actions: actions,
      template: template,
      outlineWidth: outlineWidth,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    picture.dispose();
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (byteData == null) return null;

    // 2) BFS-Füllung ab dem Tipp-Pixel.
    final seedX = ((seed.dx - region.left) * scale).floor().clamp(0, w - 1);
    final seedY = ((seed.dy - region.top) * scale).floor().clamp(0, h - 1);
    final maskBytes = _computeMask(byteData.buffer.asUint8List(), w, h,
        seedX, seedY);
    if (maskBytes == null) return null;

    // 3) Maske als Bild dekodieren.
    final mask = await _imageFromRgba(maskBytes, w, h);
    return RasterFill(mask: mask, rect: region, color: color, pattern: pattern);
  }

  /// BFS über alle Pixel, deren Farbe der Seed-Farbe ähnlich ist.
  /// Ergebnis: RGBA-Maske (weiß = gefüllt), um 1 Pixel dilatiert, damit
  /// Anti-Aliasing-Säume an den Rändern mit abgedeckt werden.
  static Uint8List? _computeMask(
      Uint8List rgba, int w, int h, int seedX, int seedY) {
    final seedIdx = (seedY * w + seedX) * 4;
    final sr = rgba[seedIdx];
    final sg = rgba[seedIdx + 1];
    final sb = rgba[seedIdx + 2];

    bool matches(int idx) {
      final dr = rgba[idx] - sr;
      final dg = rgba[idx + 1] - sg;
      final db = rgba[idx + 2] - sb;
      return dr * dr + dg * dg + db * db <= _toleranceSq;
    }

    final filled = Uint8List(w * h); // 0 = nein, 1 = gefüllt
    final queue = <int>[seedY * w + seedX];
    filled[seedY * w + seedX] = 1;
    var head = 0;
    while (head < queue.length) {
      final p = queue[head++];
      final x = p % w;
      final y = p ~/ w;
      for (final n in [
        if (x > 0) p - 1,
        if (x < w - 1) p + 1,
        if (y > 0) p - w,
        if (y < h - 1) p + w,
      ]) {
        if (filled[n] == 0 && matches(n * 4)) {
          filled[n] = 1;
          queue.add(n);
        }
      }
    }
    if (queue.isEmpty) return null;

    // Maske schreiben, inkl. 1-Pixel-Dilatation.
    final mask = Uint8List(w * h * 4);
    for (var p = 0; p < w * h; p++) {
      final x = p % w;
      final y = p ~/ w;
      final hit = filled[p] == 1 ||
          (x > 0 && filled[p - 1] == 1) ||
          (x < w - 1 && filled[p + 1] == 1) ||
          (y > 0 && filled[p - w] == 1) ||
          (y < h - 1 && filled[p + w] == 1);
      if (hit) {
        final i = p * 4;
        mask[i] = 255;
        mask[i + 1] = 255;
        mask[i + 2] = 255;
        mask[i + 3] = 255;
      }
    }
    return mask;
  }

  static Future<ui.Image> _imageFromRgba(Uint8List bytes, int w, int h) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        bytes, w, h, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }
}
