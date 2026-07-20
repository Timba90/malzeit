import 'dart:typed_data';

/// Ein gespeichertes Bild in der Galerie.
///
/// Auf Mobile zeigt [path] auf die PNG-Datei, im Web gibt es nur [bytes]
/// (Sitzungs-Galerie ohne Dateisystem).
class SavedImage {
  final String name;
  final Uint8List bytes;
  final String? path;

  const SavedImage({required this.name, required this.bytes, this.path});
}
