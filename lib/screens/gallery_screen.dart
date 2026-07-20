import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/saved_image.dart';
import '../services/save_service.dart';

/// Galerie der gespeicherten Bilder.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final SaveService _saveService = SaveService();
  List<SavedImage>? _images;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final images = await _saveService.listSavedImages();
    if (!mounted) return;
    setState(() => _images = images);
  }

  Future<void> _deleteImage(SavedImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bild löschen?'),
        content: const Text('Das Bild wird für immer entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nein'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ja, löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _saveService.deleteImage(image);
    await _loadImages();
  }

  void _showFullscreen(SavedImage image) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                child: Image.memory(image.bytes, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Schließen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text('Meine Bilder',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFB8C00),
        foregroundColor: Colors.white,
      ),
      body: images == null
          ? const Center(child: CircularProgressIndicator())
          : images.isEmpty
              ? _emptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, i) => _imageCard(images[i]),
                ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 80, color: Color(0xFFBCAAA4)),
          SizedBox(height: 16),
          Text(
            'Noch keine Bilder gespeichert.',
            style: TextStyle(fontSize: 20, color: Color(0xFF5D4037)),
          ),
          if (kIsWeb)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Im Browser werden Bilder nur während der Sitzung angezeigt.',
                style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _imageCard(SavedImage image) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showFullscreen(image),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(image.bytes, fit: BoxFit.cover),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.white70,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFE53935)),
                  tooltip: 'Löschen',
                  onPressed: () => _deleteImage(image),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
