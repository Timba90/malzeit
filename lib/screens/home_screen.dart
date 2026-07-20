import 'dart:convert' show utf8;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/svg_template.dart';
import '../services/svg_service.dart';
import '../state/drawing_provider.dart';
import 'drawing_screen.dart';
import 'gallery_screen.dart';

/// Hauptmenü: Vorlagen nach Kategorien + "Frei malen" + Galerie.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Kategorien aus verfügbaren Vorlagen gruppieren
    final Map<String, List<TemplateInfo>> byCategory = {};
    for (final t in SvgService.availableTemplates) {
      byCategory.putIfAbsent(t.category, () => []).add(t);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text('Malzeit',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFB8C00),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Frei malen
          _bigCard(
            context,
            title: 'Frei malen',
            icon: Icons.gesture,
            color: const Color(0xFF00897B),
            onTap: () {
              final provider = context.read<DrawingProvider>();
              provider.setTemplate(null);
              provider.setMode(DrawMode.free);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DrawingScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          // Galerie
          _bigCard(
            context,
            title: 'Meine Bilder',
            icon: Icons.photo_library,
            color: const Color(0xFFFB8C00),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GalleryScreen()),
            ),
          ),
          const SizedBox(height: 16),
          // Eigene SVG hochladen
          _bigCard(
            context,
            title: 'Eigenes Bild hochladen (SVG)',
            icon: Icons.upload_file,
            color: const Color(0xFF8E24AA),
            onTap: () => _uploadSvg(context),
          ),
          const SizedBox(height: 24),
          // Kategorien
          for (final entry in byCategory.entries) ...[
            Text(entry.key,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037))),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entry.value.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) =>
                    _templateCard(context, entry.value[i]),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Future<void> _uploadSvg(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['svg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    try {
      // UTF-8 dekodieren, damit Umlaute u. ä. korrekt ankommen
      final raw = utf8.decode(bytes, allowMalformed: true);
      final template = SvgService().loadUserTemplate(raw, file.name);
      if (!context.mounted) return;
      _openTemplate(context, template);
    } on SvgTemplateException catch (e) {
      if (!context.mounted) return;
      _showError(context, e.message);
    } catch (_) {
      if (!context.mounted) return;
      _showError(context, 'Diese Datei konnte nicht gelesen werden.');
    }
  }

  Future<void> _openAssetTemplate(
      BuildContext context, TemplateInfo info) async {
    try {
      final template = await SvgService().loadTemplate(info);
      if (!context.mounted) return;
      _openTemplate(context, template);
    } on SvgTemplateException catch (e) {
      if (!context.mounted) return;
      _showError(context, e.message);
    } catch (_) {
      if (!context.mounted) return;
      _showError(context, 'Die Vorlage konnte nicht geladen werden.');
    }
  }

  void _openTemplate(BuildContext context, SvgTemplate template) {
    final provider = context.read<DrawingProvider>();
    provider.setTemplate(template);
    provider.setMode(DrawMode.fields);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DrawingScreen()),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _templateCard(BuildContext context, TemplateInfo info) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openAssetTemplate(context, info),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SvgPicture.asset(
                  info.assetPath,
                  placeholderBuilder: (_) => const Icon(Icons.image,
                      size: 56, color: Color(0xFFFB8C00)),
                ),
              ),
              const SizedBox(height: 10),
              Text(info.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Row(
            children: [
              Icon(icon, size: 44, color: Colors.white),
              const SizedBox(width: 20),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
