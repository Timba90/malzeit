// Diese Datei wird nur im Web-Build eingebunden (conditional import).
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/widgets.dart';

import '../models/saved_image.dart';
import 'canvas_capture.dart';

/// Web-Variante: bietet das PNG als Browser-Download an und merkt sich
/// gespeicherte Bilder für die Galerie in der laufenden Sitzung.
class SaveService {
  static final List<SavedImage> _sessionGallery = [];

  Future<String?> saveCanvasToGallery(GlobalKey canvasKey) async {
    try {
      final bytes = await captureCanvasPng(canvasKey);
      if (bytes == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'malzeit_$timestamp.png';

      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..download = fileName
        ..click();
      html.Url.revokeObjectUrl(url);

      _sessionGallery.insert(0, SavedImage(name: fileName, bytes: bytes));
      return fileName;
    } catch (e) {
      debugPrint('Speichern fehlgeschlagen: $e');
      return null;
    }
  }

  Future<List<SavedImage>> listSavedImages() async =>
      List.unmodifiable(_sessionGallery);

  Future<bool> deleteImage(SavedImage image) async {
    _sessionGallery.remove(image);
    return true;
  }
}
