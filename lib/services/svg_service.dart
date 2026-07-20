import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart';

import '../models/svg_template.dart';

/// Übersetzt SVG-Path-Daten (d-Attribut) in ein dart:ui Path-Objekt.
class _PathBuilder extends PathProxy {
  Path path = Path();

  @override
  void close() => path.close();

  @override
  void cubicTo(
          double x1, double y1, double x2, double y2, double x3, double y3) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}

/// Lädt SVG-Vorlagen und zerlegt sie in ausfüllbare Felder.
///
/// Konvention für Vorlagen-SVGs:
/// - Jedes füllbare Element (path/rect/circle/ellipse/polygon) mit id="feld-*"
///   wird ein Ausmalfeld.
/// - Gruppen <g data-layer="N"> definieren die Ebene (Standard: 0).
/// - Nicht-füllbare Linien (id="linie-*" oder fill="none") werden nur als
///   Outline gezeichnet.
class SvgService {
  static const String templateBasePath = 'assets/svg/templates/';

  /// Verfügbare Vorlagen (wird später aus Asset-Manifest gelesen).
  static const List<TemplateInfo> availableTemplates = [
    TemplateInfo(
        name: 'Dino', category: 'Dinos', assetPath: '${templateBasePath}dinos/dino.svg'),
    TemplateInfo(
        name: 'Auto', category: 'Autos', assetPath: '${templateBasePath}autos/auto.svg'),
    TemplateInfo(
        name: 'Schlange',
        category: 'Schlangen',
        assetPath: '${templateBasePath}schlangen/schlange.svg'),
    TemplateInfo(
        name: 'Blume',
        category: 'Pflanzen',
        assetPath: '${templateBasePath}blumen/blume.svg'),
  ];

  /// Lädt eine mitgelieferte Vorlage aus den Assets.
  ///
  /// Manche Web-Deploys liefern Asset-Keys mit doppeltem bzw. fehlendem
  /// "assets/"-Präfix aus — deshalb werden Pfad-Varianten durchprobiert.
  Future<SvgTemplate> loadTemplate(TemplateInfo info) async {
    final raw = await _loadAssetString(info.assetPath);
    return parseTemplate(raw, info);
  }

  Future<String> _loadAssetString(String assetPath) async {
    final candidates = <String>[
      assetPath,
      'assets/$assetPath',
      if (assetPath.startsWith('assets/'))
        assetPath.substring('assets/'.length),
    ];
    Object? lastError;
    for (final path in candidates) {
      try {
        return await rootBundle.loadString(path);
      } catch (e) {
        lastError = e;
      }
    }
    throw SvgTemplateException(
        'Vorlage konnte nicht geladen werden ($assetPath): $lastError');
  }

  /// Lädt eine eigene SVG-Datei (vom Nutzer hochgeladen) als Vorlage.
  /// Wirft eine Exception, wenn keine ausfüllbaren Felder gefunden werden.
  SvgTemplate loadUserTemplate(String rawSvg, String fileName) {
    final info = TemplateInfo(
      name: fileName.replaceAll('.svg', ''),
      category: 'Eigene',
      assetPath: '',
    );
    final template = parseTemplate(rawSvg, info);
    if (template.fields.isEmpty) {
      throw const SvgTemplateException(
          'Diese SVG hat keine ausfüllbaren Felder. Tipp: Formen brauchen ein fill-Attribut.');
    }
    return template;
  }

  /// Parst ein SVG (aus String) und extrahiert Felder, Ebenen und viewBox.
  SvgTemplate parseTemplate(String rawSvg, TemplateInfo info) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(rawSvg);
    } on XmlException {
      throw const SvgTemplateException(
          'Diese Datei ist kein gültiges SVG-Bild.');
    }
    final svgRoot = doc.rootElement;

    // viewBox ermitteln
    Size viewBox = const Size(300, 300);
    final viewBoxAttr = svgRoot.getAttribute('viewBox');
    if (viewBoxAttr != null) {
      final parts = viewBoxAttr
          .trim()
          .split(RegExp(r'[\s,]+'))
          .map(double.tryParse)
          .toList();
      if (parts.length == 4 && parts.every((p) => p != null)) {
        viewBox = Size(parts[2]!, parts[3]!);
      }
    }

    final fields = <SvgField>[];
    int maxLayer = 0;
    var fieldCounter = 0;

    void walk(XmlElement el, int layer) {
      final layerAttr = el.getAttribute('data-layer');
      final effectiveLayer =
          layerAttr != null ? int.tryParse(layerAttr) ?? layer : layer;
      if (effectiveLayer > maxLayer) maxLayer = effectiveLayer;

      final isShape = const {
        'path',
        'rect',
        'circle',
        'ellipse',
        'polygon'
      }.contains(el.name.local);
      if (isShape) {
        final id = el.getAttribute('id') ?? '';
        final fill = el.getAttribute('fill');
        final isOutline = id.startsWith('linie-') || fill == 'none';
        if (!isOutline) {
          final p = _elementToPath(el);
          if (p != null) {
            fieldCounter++;
            fields.add(SvgField(
              id: id.isNotEmpty ? id : 'feld-$fieldCounter',
              path: p,
              layer: effectiveLayer,
            ));
          }
        }
      }

      for (final child in el.childElements) {
        walk(child, effectiveLayer);
      }
    }

    walk(svgRoot, 0);

    return SvgTemplate(
      name: info.name,
      category: info.category,
      fields: fields,
      viewBox: viewBox,
      layerCount: maxLayer + 1,
      rawSvg: rawSvg,
    );
  }

  Path? _elementToPath(XmlElement el) {
    switch (el.name.local) {
      case 'path':
        final d = el.getAttribute('d');
        if (d == null) return null;
        final builder = _PathBuilder();
        writeSvgPathDataToPath(d, builder);
        return builder.path;
      case 'rect':
        final x = _num(el, 'x');
        final y = _num(el, 'y');
        final w = _num(el, 'width');
        final h = _num(el, 'height');
        return Path()..addRect(Rect.fromLTWH(x, y, w, h));
      case 'circle':
        final cx = _num(el, 'cx');
        final cy = _num(el, 'cy');
        final r = _num(el, 'r');
        return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      case 'ellipse':
        final cx = _num(el, 'cx');
        final cy = _num(el, 'cy');
        final rx = _num(el, 'rx');
        final ry = _num(el, 'ry');
        return Path()
          ..addOval(Rect.fromCenter(
              center: Offset(cx, cy), width: rx * 2, height: ry * 2));
      case 'polygon':
        final pointsAttr = el.getAttribute('points');
        if (pointsAttr == null) return null;
        final nums = pointsAttr
            .trim()
            .split(RegExp(r'[\s,]+'))
            .map(double.tryParse)
            .whereType<double>()
            .toList();
        if (nums.length < 6) return null;
        final p = Path()..moveTo(nums[0], nums[1]);
        for (var i = 2; i + 1 < nums.length; i += 2) {
          p.lineTo(nums[i], nums[i + 1]);
        }
        p.close();
        return p;
    }
    return null;
  }

  double _num(XmlElement el, String attr) =>
      double.tryParse(el.getAttribute(attr) ?? '') ?? 0.0;
}

/// Fehler beim Laden einer Nutzer-SVG.
class SvgTemplateException implements Exception {
  final String message;
  const SvgTemplateException(this.message);

  @override
  String toString() => message;
}
