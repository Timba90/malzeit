import 'package:flutter/material.dart';

import '../models/drawing_models.dart';
import '../models/svg_template.dart';

/// Werkzeug, das gerade aktiv ist.
enum Tool { brush, eraser, fill }

/// Mal-Modus der App.
enum DrawMode { free, fields }

/// Zentraler Zustand der Mal-App (ein Profil, kein Login).
class DrawingProvider extends ChangeNotifier {
  // ---- Werkzeug & Farbe ----
  Tool _currentTool = Tool.brush;
  BrushType _brushType = BrushType.solid;
  Color _currentColor = const Color(0xFFF44336); // Rot als Startfarbe
  double _strokeWidth = 14.0;
  DrawMode _mode = DrawMode.fields;

  /// Muster für das Füll-Werkzeug (null = einfarbig).
  FillPattern? _fillPattern;

  // ---- Leinwand-Inhalt (Undo-Historie: Striche + Füllungen) ----
  final List<DrawAction> _actions = [];
  DrawStroke? _activeStroke;

  /// Läuft gerade eine (asynchrone) Flood-Fill-Berechnung?
  bool _filling = false;

  // ---- Vorlage & Felder ----
  SvgTemplate? _template;
  String? _selectedFieldId;

  static const double minStrokeWidth = 4.0;
  static const double maxStrokeWidth = 40.0;

  // ---- Kindgerechte Farbpalette ----
  static const List<Color> palette = [
    Color(0xFFF44336), // Rot
    Color(0xFFFF9800), // Orange
    Color(0xFFFFEB3B), // Gelb
    Color(0xFF8BC34A), // Hellgrün
    Color(0xFF2E7D32), // Dunkelgrün
    Color(0xFF4FC3F7), // Himmelblau
    Color(0xFF1565C0), // Blau
    Color(0xFF9C27B0), // Lila
    Color(0xFFF48FB1), // Rosa
    Color(0xFFFFCC80), // Hautton
    Color(0xFF795548), // Braun
    Color(0xFF9E9E9E), // Grau
    Color(0xFF000000), // Schwarz
    Color(0xFFFFFFFF), // Weiß
  ];

  // ---- Getter ----
  Tool get currentTool => _currentTool;
  BrushType get brushType => _brushType;
  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;
  DrawMode get mode => _mode;
  FillPattern? get fillPattern => _fillPattern;
  List<DrawAction> get actions => List.unmodifiable(_actions);
  DrawStroke? get activeStroke => _activeStroke;
  bool get isFilling => _filling;
  SvgTemplate? get template => _template;
  String? get selectedFieldId => _selectedFieldId;
  bool get canUndo => _actions.isNotEmpty || _activeStroke != null;
  bool get hasContent => canUndo;

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

  void setBrushType(BrushType type) {
    _brushType = type;
    _currentTool = Tool.brush; // Pinsel-Typ setzen => automatisch Pinsel aktiv
    notifyListeners();
  }

  /// Farbe wählen. Der gewählte Pinsel-Typ bleibt erhalten, nur der
  /// Regenbogen-Pinsel (ignoriert Farben) wechselt zurück auf solid.
  /// Das Füll-Werkzeug bleibt aktiv (Farbe wählen + tippen = füllen).
  void setColor(Color color) {
    _currentColor = color;
    if (_brushType == BrushType.rainbow) {
      _brushType = BrushType.solid;
    }
    if (_currentTool == Tool.eraser) _currentTool = Tool.brush;
    notifyListeners();
  }

  /// Muster wählen (null = einfarbig) — aktiviert automatisch den Farbeimer.
  void setFillPattern(FillPattern? pattern) {
    _fillPattern = pattern;
    _currentTool = Tool.fill;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width.clamp(minStrokeWidth, maxStrokeWidth);
    notifyListeners();
  }

  void setMode(DrawMode mode) {
    _mode = mode;
    notifyListeners();
  }

  // ---- Vorlagen ----
  void setTemplate(SvgTemplate? template) {
    _template = template;
    _selectedFieldId = template != null && template.fields.isNotEmpty
        ? template.fields.first.id
        : null;
    clearAll();
  }

  void selectField(String fieldId) {
    _selectedFieldId = fieldId;
    notifyListeners();
  }

  /// Wählt das Feld an der gegebenen Position (SVG-Koordinaten).
  /// Felder höherer Ebenen liegen "oben" und gewinnen bei Überlappung.
  bool selectFieldAt(Offset svgPoint) {
    if (_template == null) return false;
    final sorted = [..._template!.fields]
      ..sort((a, b) => b.layer.compareTo(a.layer));
    for (final field in sorted) {
      if (field.contains(svgPoint)) {
        _selectedFieldId = field.id;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // ---- Füllen (Farbeimer) ----

  /// Füllt das aktuell gewählte Feld mit Farbe bzw. Muster.
  void fillSelectedField() {
    final field = selectedField;
    if (field == null) return;
    _actions.add(FieldFill(
      fieldId: field.id,
      color: _currentColor,
      pattern: _fillPattern,
    ));
    notifyListeners();
  }

  /// Fügt ein fertig berechnetes Flood-Fill-Ergebnis hinzu (Frei-Modus).
  void addRasterFill(RasterFill fill) {
    _actions.add(fill);
    notifyListeners();
  }

  /// Markiert Beginn/Ende einer asynchronen Füll-Berechnung
  /// (verhindert doppelte Fills bei schnellem Tippen).
  void beginFill() {
    _filling = true;
    notifyListeners();
  }

  void endFill() {
    _filling = false;
    notifyListeners();
  }

  // ---- Malen ----
  void startStroke(Offset svgPoint) {
    if (_currentTool == Tool.fill) return; // Füllen läuft über Tap
    if (_mode == DrawMode.fields && _selectedFieldId == null) return;

    final isEraser = _currentTool == Tool.eraser;
    _activeStroke = DrawStroke(
      color: _currentColor,
      strokeWidth: _strokeWidth,
      isEraser: isEraser,
      fieldId: _mode == DrawMode.fields ? _selectedFieldId : null,
      brushType: isEraser ? BrushType.solid : _brushType,
    );
    _activeStroke!.points
        .add(DrawPoint(position: svgPoint, color: _currentColor));
    notifyListeners();
  }

  void extendStroke(Offset svgPoint) {
    final stroke = _activeStroke;
    if (stroke == null) return;

    // Regenbogen-Pinsel: HSV-Hue kontinuierlich rotieren
    Color pointColor = _currentColor;
    if (stroke.brushType == BrushType.rainbow) {
      final hue = (stroke.points.length * 4.0) % 360.0;
      pointColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
    }

    stroke.points.add(DrawPoint(position: svgPoint, color: pointColor));
    notifyListeners();
  }

  void endStroke() {
    final stroke = _activeStroke;
    if (stroke == null) return;
    if (stroke.points.isNotEmpty) {
      _actions.add(stroke);
    }
    _activeStroke = null;
    notifyListeners();
  }

  /// Macht die letzte Aktion (Strich oder Füllung) rückgängig.
  void undo() {
    if (_activeStroke != null) {
      _activeStroke = null;
    } else if (_actions.isNotEmpty) {
      final removed = _actions.removeLast();
      if (removed is RasterFill) removed.dispose();
    } else {
      return;
    }
    notifyListeners();
  }

  /// Löscht das gesamte Bild.
  void clearAll() {
    for (final action in _actions) {
      if (action is RasterFill) action.dispose();
    }
    _actions.clear();
    _activeStroke = null;
    notifyListeners();
  }
}
