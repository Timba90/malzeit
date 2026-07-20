import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/save_service.dart';
import '../state/drawing_provider.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/toolbar.dart';

/// Der Malbereich: Canvas + Toolbar.
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  bool _saving = false;

  Future<void> _saveImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final path = await SaveService().saveCanvasToGallery(_canvasKey);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null
              ? 'Bild gespeichert! 🎨'
              : 'Speichern fehlgeschlagen'),
          backgroundColor:
              path != null ? const Color(0xFF43A047) : Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DrawingProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Kopfzeile mit Vorlagen-Name und Feld-Auswahl
            if (provider.template != null)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF3E0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        provider.template!.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (provider.mode == DrawMode.fields)
                      const Row(
                        children: [
                          Icon(Icons.touch_app,
                              size: 18, color: Color(0xFF1E88E5)),
                          SizedBox(width: 4),
                          Text(
                            'Tippe auf ein Feld zum Ausmalen',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFF1E88E5)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            // Canvas
            Expanded(
              child: RepaintBoundary(
                key: _canvasKey,
                child: const DrawingCanvas(),
              ),
            ),
            // Toolbar
            DrawingToolbar(
              onSave: _saving ? null : _saveImage,
              onBack: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
