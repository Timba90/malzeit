import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../models/saved_image.dart';
import 'canvas_capture.dart';

/// Speichert den aktuellen Canvas als PNG-Datei (Android/iOS/Desktop).
class SaveService {
  Future<String?> saveCanvasToGallery(GlobalKey canvasKey) async {
    try {
      final bytes = await captureCanvasPng(canvasKey);
      if (bytes == null) return null;

      final galleryDir = await _galleryDir();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${galleryDir.path}/malzeit_$timestamp.png');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Speichern fehlgeschlagen: $e');
      return null;
    }
  }

  Future<List<SavedImage>> listSavedImages() async {
    try {
      final galleryDir = await _galleryDir();
      final files = await galleryDir
          .list()
          .where((e) => e is File && e.path.endsWith('.png'))
          .cast<File>()
          .toList();
      files.sort((a, b) => b.path.compareTo(a.path)); // Zeitstempel im Namen
      final images = <SavedImage>[];
      for (final f in files) {
        images.add(SavedImage(
          name: f.uri.pathSegments.last,
          bytes: await f.readAsBytes(),
          path: f.path,
        ));
      }
      return images;
    } catch (e) {
      debugPrint('Galerie konnte nicht geladen werden: $e');
      return [];
    }
  }

  Future<bool> deleteImage(SavedImage image) async {
    final path = image.path;
    if (path == null) return false;
    try {
      await File(path).delete();
      return true;
    } catch (e) {
      debugPrint('Löschen fehlgeschlagen: $e');
      return false;
    }
  }

  Future<Directory> _galleryDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final galleryDir = Directory('${dir.path}/bilder');
    if (!await galleryDir.exists()) {
      await galleryDir.create(recursive: true);
    }
    return galleryDir;
  }
}
