import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Speichert den aktuellen Canvas als PNG-Datei (Android/iOS).
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

      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final galleryDir = Directory('${dir.path}/bilder');
      if (!await galleryDir.exists()) {
        await galleryDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${galleryDir.path}/malzeit_$timestamp.png');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<List<File>> listSavedImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final galleryDir = Directory('${dir.path}/bilder');
    if (!await galleryDir.exists()) return [];
    final files = await galleryDir
        .list()
        .where((e) => e is File && e.path.endsWith('.png'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }
}
