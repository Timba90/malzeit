# Malzeit — Kinder-Mal-App

## Überblick
Flutter-App für Tablets (iOS + Android), Zielgruppe 3-6 Jahre.
Einmaliger Kauf (10€), keine In-App-Käufe, keine Werbung.

## Tech Stack
- Flutter 3.19+ / Dart
- Provider für State Management
- flutter_svg, path_parsing, xml für SVG-Verarbeitung
- file_picker für SVG-Upload
- Custom CustomPainter Canvas für Zeichnung

## Architektur
- `lib/main.dart` — App-Entry, ChangeNotifierProvider
- `lib/models/` — DrawAction (DrawStroke/FieldFill/RasterFill), DrawPoint, BrushType, FillPattern, SvgField, SvgTemplate, SavedImage
- `lib/state/drawing_provider.dart` — Zentraler State (Werkzeug, Farbe, Muster, Modi, Aktions-Historie, Undo)
- `lib/painting/action_painter.dart` — Gemeinsames Rendering aller DrawActions (Live-Canvas + Flood-Fill-Raster)
- `lib/painting/pattern_painter.dart` — 8 programmierte Füll-Muster
- `lib/services/svg_service.dart` — SVG-Parsing, Feld-Zerlegung, Template-Loading (mit Asset-Pfad-Fallback für Web)
- `lib/services/flood_fill_service.dart` — Flood-Fill (Raster + BFS + Alpha-Maske) für Frei-Modus
- `lib/services/save_service.dart` — PNG-Speicherung + Galerie (conditional import io/web)
- `lib/services/canvas_capture.dart` — Gemeinsamer PNG-Capture-Helper
- `lib/widgets/drawing_canvas.dart` — CustomPainter, Tap-Handling (Farbeimer) + Pan (Pinsel)
- `lib/widgets/toolbar.dart` — Werkzeugleiste (bunte Werkzeug-Icons, Muster-Raster, runde Aktions-Buttons)
- `lib/screens/` — splash, home (Kategorien), drawing, gallery
- `assets/svg/templates/` — Ausmalvorlagen (Dinos, Autos, Schlangen, Blumen)

## Features
- 4 Pinsel-Typen: solid, star (Sternen-Spur), glitter (Punkte-Spur), rainbow (HSV-Hue)
- Füllwerkzeug (Farbeimer): Feld-Modus füllt getipptes SVG-Feld, Frei-Modus macht pixelbasierten Flood-Fill (Raster 800px, Toleranz-BFS, Ergebnis als Alpha-Masken-Image in der Undo-Historie)
- 8 Füll-Muster (Punkte, Streifen, Sterne, Herzen, Karo, Schuppen, Regenbogen, Blumen) — programmiert via CustomPaint, kombinierbar mit jeder Palettenfarbe
- Radiergummi, Rückgängig (letzte Aktion: Strich oder Füllung), einstellbare Pinselgröße (Slider mit Vorschau)
- Zwei Modi: Frei malen / Feld-basiert (Striche werden auf SVG-Feld beschnitten)
- SVG-Vorlagen: Parser zerlegt in Felder (path/rect/circle/ellipse/polygon) + Ebenen (data-layer)
- 14-Farben-Palette (inkl. Hautton, Grau)
- Bild als PNG speichern (Mobile: Dateisystem, Web: Browser-Download)
- Galerie gespeicherter Bilder (Web: nur Sitzungs-Galerie)
- Eigene SVGs hochladen (UTF-8-dekodiert)

## Web-Demo
GitHub Pages: https://timba90.github.io/malzeit/
GitHub Repo: https://github.com/Timba90/malzeit

## Known Issues
1. Web-Galerie ist nur eine Sitzungs-Galerie (kein persistenter Speicher im Browser)
2. SVG-Parser ignoriert transform-Attribute (Vorlagen dürfen keine Transforms nutzen)
3. Undo entfernt nur Striche, "Leeren" ist nicht rückgängig machbar

## Code Style
- Deutsch für UI-Texte
- Englisch für Code/Kommentare
- Material Design 3
- Kindgerechte UI: große Buttons, klare Symbole, keine Text-Menüs
