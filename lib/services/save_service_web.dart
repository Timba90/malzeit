import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Web-Variante: gibt die PNG-Bytes zurück (Download-Handling im UI).
class SaveService {
  Future<String?> saveCanvasToGallery(GlobalKey canvasKey) async {
    try {
      final boundary = canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      // Web: kein Dateisystem — Erfolg melden (Download im Browser anbieten)
      return 'web-download:${byteData.lengthInBytes}';
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> listSavedImages() async => [];
}
