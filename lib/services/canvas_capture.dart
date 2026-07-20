import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Rendert den Canvas hinter [canvasKey] als PNG-Bytes.
/// Gibt null zurück, wenn der Canvas (noch) nicht gerendert wurde.
Future<Uint8List?> captureCanvasPng(GlobalKey canvasKey,
    {double pixelRatio = 3.0}) async {
  final boundary =
      canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;

  final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
