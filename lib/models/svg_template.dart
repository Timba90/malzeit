import 'dart:ui';

/// Ein ausfüllbares Feld innerhalb einer SVG-Vorlage.
class SvgField {
  /// Eindeutige Identität (SVG-Element-ID oder generiert).
  final String id;

  /// Pfad der Feld-Umrandung (in SVG-Koordinaten).
  final Path path;

  /// Ebene der Vorlage, zu der das Feld gehört (0-basiert).
  final int layer;

  const SvgField({
    required this.id,
    required this.path,
    required this.layer,
  });

  /// Prüft, ob ein Punkt innerhalb des Feldes liegt.
  bool contains(Offset point) => path.contains(point);
}

/// Eine geladene SVG-Ausmalvorlage mit ihren Feldern.
class SvgTemplate {
  final String name;
  final String category;
  final List<SvgField> fields;
  final Size viewBox;

  /// Anzahl der Ebenen in dieser Vorlage.
  final int layerCount;

  /// Roh-SVG-Inhalt für die Outline-Darstellung.
  final String rawSvg;

  const SvgTemplate({
    required this.name,
    required this.category,
    required this.fields,
    required this.viewBox,
    required this.layerCount,
    required this.rawSvg,
  });
}

/// Metadaten einer Vorlage in der Auswahlliste.
class TemplateInfo {
  final String name;
  final String category;
  final String assetPath;

  const TemplateInfo({
    required this.name,
    required this.category,
    required this.assetPath,
  });
}
