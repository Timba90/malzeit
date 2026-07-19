import 'package:flutter/material.dart';

import '../models/decoration_models.dart' as deco;
import '../models/drawing_models.dart';
import '../models/svg_template.dart';

/// Werkzeug, das gerade aktiv ist.
enum Tool { brush, eraser, star, glitter }

/// Mal-Modus der App.
enum DrawMode { free, fields }

/// Zentraler Zustand der Mal-App (ein Profil, kein Login).
class DrawingProvider extends ChangeNotifier {
  // ---- Werkzeug & Farbe ----
  Tool _currentTool = Tool.brush;
  Color _currentColor = const Color(0xFFE53935); // Rot als Startfarbe
  double _strokeWidth = 14.0;
  DrawMode _mode = DrawMode.fields;

  // ---- Leinwand-Inhalt ----
  final List<DrawStroke> _strokes = [];
  DrawStroke? _activeStroke;
  final List<deco.Decoration> _decorations = [];

  // ---- Vorlage & Felder ----
  SvgTemplate? _template;
  String? _selectedFieldId;

  // ---- Kindgerechte Farbpalette (10 Farben) ----
  static const List<Color> palette = [
    Color(0xFFE53935), // Rot
    Color(0xFFFB8C00), // Orange
    Color(0xFFFDD835), // Gelb
    Color(0xFF43A047), // Grün
    Color(0xFF1E88E5), // Blau
    Color(0xFF8E24AA), // Lila
    Color(0xFFD81B60), // Pink
    Color(0xFF6D4C41), // Braun
    Color(0xFF000000), // Schwarz
    Color(0xFFFFFFFF), // Weiß
  ];

  // ---- Getter ----
  Tool get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;
  DrawMode get mode => _mode;
  List<DrawStroke> get strokes => List.unmodifiable(_strokes);
  DrawStroke? get activeStroke => _activeStroke;
  List<deco.Decoration> get decorations => List.unmodifiable(_decorations);
  SvgTemplate? get template => _template;
  String? get selectedFieldId => _selectedFieldId;

  SvgField? get selectedField {
    if (_template == null || _selectedFieldId == null) return null;
    for (final f in _template!.fields) {
      if (f.id == _selectedFieldId) return f;
    }
    return null;
  }

  // ---- Werkzeug-Aktionen ----
  void setTool(Tool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    // Bei Farbwahl automatisch zurück zum Pinsel (außer Radierer gewünscht)
    if (_currentTool == Tool.eraser) _currentTool = Tool.brush;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width.clamp(4.0, 40.0);
    notifyListeners();
  }

  void setMode(DrawMode mode) {
    _mode = mode;
    notifyListeners();
  }

  // ---- Vorlagen ----
  void setTemplate(SvgTemplate? template) {
    _template = template;
    _selectedFieldId =
        template != null && template.fields.isNotEmpty ? template.fields.first.id : null;
    clearAll();
  }

  void selectField(String fieldId) {
    _selectedFieldId = fieldId;
    notifyListeners();
  }

  /// Wählt das Feld an der gegebenen Position (SVG-Koordinaten).
  bool selectFieldAt(Offset svgPoint) {
    if (_template == null) return false;
    // Von oben nach unten (höchste Ebene zuerst)
    final sorted = [..._template!.fields]..sort((a, b) => b.layer.compareTo(a.layer));
    for (final field in sorted) {
      if (field.contains(svgPoint)) {
        _selectedFieldId = field.id;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // ---- Malen ----
  void startStroke(Offset svgPoint) {
    if (_currentTool == Tool.star || _currentTool == Tool.glitter) {
      addDecoration(svgPoint);
      return;
    }
    if (_mode == DrawMode.fields && _selectedFieldId == null) return;

    _activeStroke = DrawStroke(
      color: _currentColor,
      strokeWidth: _strokeWidth,
      isEraser: _currentTool == Tool.eraser,
      fieldId: _mode == DrawMode.fields ? _selectedFieldId : null,
    );
    _activeStroke!.points.add(DrawPoint(
      position: svgPoint,
      color: _currentColor,
      strokeWidth: _strokeWidth,
      isEraser: _currentTool == Tool.eraser,
      fieldId: _activeStroke!.fieldId,
    ));
    notifyListeners();
  }

  void extendStroke(Offset svgPoint) {
    if (_activeStroke == null) return;
    _activeStroke!.points.add(DrawPoint(
      position: svgPoint,
      color: _activeStroke!.color,
      strokeWidth: _activeStroke!.strokeWidth,
      isEraser: _activeStroke!.isEraser,
      fieldId: _activeStroke!.fieldId,
    ));
    notifyListeners();
  }

  void endStroke() {
    if (_activeStroke == null) return;
    if (_activeStroke!.points.isNotEmpty) {
      _strokes.add(_activeStroke!);
    }
    _activeStroke = null;
    notifyListeners();
  }

  void addDecoration(Offset svgPoint) {
    final type =
        _currentTool == Tool.star ? deco.DecorationType.star : deco.DecorationType.glitter;
    _decorations.add(deco.Decoration(
      position: svgPoint,
      type: type,
      fieldId: _mode == DrawMode.fields ? _selectedFieldId : null,
    ));
    notifyListeners();
  }

  /// Löscht das gesamte Bild.
  void clearAll() {
    _strokes.clear();
    _decorations.clear();
    _activeStroke = null;
    notifyListeners();
  }
}
