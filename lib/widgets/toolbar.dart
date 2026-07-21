import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drawing_models.dart';
import '../painting/pattern_painter.dart';
import '../state/drawing_provider.dart';

/// Untere Werkzeugleiste: Werkzeuge, Pinselgröße, Muster, Farben, Aktionen.
/// Kindgerecht: große Buttons (min. 56px), jedes Werkzeug mit eigener
/// Leuchtfarbe, runde Aktions-Buttons, kein Überlaufen — der Werkzeugbereich
/// scrollt horizontal, die Aktionen bleiben fest sichtbar.
class DrawingToolbar extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onBack;

  const DrawingToolbar({super.key, this.onSave, this.onBack});

  static const _animDuration = Duration(milliseconds: 200);
  static const _selectedColor = Color(0xFF1E88E5);

  // Leuchtfarben der Werkzeuge
  static const _brushColor = Color(0xFFFF9800); // Orange
  static const _fillColor = Color(0xFF9C27B0); // Lila
  static const _starColor = Color(0xFFEC407A); // Pink
  static const _eraserColor = Color(0xFF4FC3F7); // Hellblau

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DrawingProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zeile 1: Werkzeuge (scrollbar) + feste Aktionen
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ToolButton(
                        icon: Icons.brush,
                        label: 'Pinsel',
                        color: _brushColor,
                        selected: provider.currentTool == Tool.brush &&
                            provider.brushType == BrushType.solid,
                        onTap: () => provider.setBrushType(BrushType.solid),
                      ),
                      _ToolButton(
                        icon: Icons.format_color_fill,
                        label: 'Füllen',
                        color: _fillColor,
                        selected: provider.currentTool == Tool.fill,
                        onTap: () => provider.setTool(Tool.fill),
                      ),
                      _ToolButton(
                        icon: Icons.star,
                        label: 'Sterne',
                        color: _starColor,
                        selected: provider.currentTool == Tool.brush &&
                            provider.brushType == BrushType.star,
                        onTap: () => provider.setBrushType(BrushType.star),
                      ),
                      _ToolButton(
                        icon: Icons.auto_awesome,
                        label: 'Glitzer',
                        color: _starColor,
                        selected: provider.currentTool == Tool.brush &&
                            provider.brushType == BrushType.glitter,
                        onTap: () => provider.setBrushType(BrushType.glitter),
                        rainbow: true,
                      ),
                      _ToolButton(
                        icon: Icons.looks,
                        label: 'Regenbogen',
                        color: _selectedColor,
                        selected: provider.currentTool == Tool.brush &&
                            provider.brushType == BrushType.rainbow,
                        onTap: () => provider.setBrushType(BrushType.rainbow),
                        rainbow: true,
                      ),
                      _ToolButton(
                        icon: Icons.auto_fix_off,
                        label: 'Radierer',
                        color: _eraserColor,
                        selected: provider.currentTool == Tool.eraser,
                        onTap: () => provider.setTool(Tool.eraser),
                      ),
                      if (provider.template != null) _ModeToggle(provider),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Feste Aktionen: immer sichtbar, groß und rund
              _RoundActionButton(
                icon: Icons.undo,
                label: 'Zurück',
                color: const Color(0xFF8E24AA),
                enabled: provider.canUndo,
                onTap: provider.undo,
              ),
              _RoundActionButton(
                icon: Icons.delete_outline,
                label: 'Leeren',
                color: const Color(0xFFE53935),
                enabled: provider.hasContent,
                onTap: () => _confirmClear(context, provider),
              ),
              if (onSave != null)
                _RoundActionButton(
                  icon: Icons.save_alt,
                  label: 'Sichern',
                  color: const Color(0xFF43A047),
                  onTap: onSave,
                ),
              if (onBack != null)
                _RoundActionButton(
                  icon: Icons.home,
                  label: 'Menü',
                  color: const Color(0xFFFDD835), // Gelb
                  iconColor: const Color(0xFF5D4037),
                  onTap: onBack,
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Zeile 2: Pinselgröße (nur für Pinsel/Radierer relevant)
          if (provider.currentTool != Tool.fill) _BrushSizeSlider(provider),
          // Zeile 2b: Muster-Auswahl (nur beim Füll-Werkzeug)
          if (provider.currentTool == Tool.fill) _PatternRow(provider),
          const SizedBox(height: 6),
          // Zeile 3: Farbpalette
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: DrawingProvider.palette.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final color = DrawingProvider.palette[i];
                final selected = provider.currentColor == color &&
                    provider.currentTool != Tool.eraser &&
                    provider.brushType != BrushType.rainbow;
                return GestureDetector(
                  onTap: () => provider.setColor(color),
                  child: AnimatedScale(
                    scale: selected ? 1.12 : 1.0,
                    duration: _animDuration,
                    child: AnimatedContainer(
                      duration: _animDuration,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? _selectedColor : Colors.black26,
                          width: selected ? 4 : 1.5,
                        ),
                        boxShadow: selected
                            ? const [
                                BoxShadow(
                                    color: Colors.black26, blurRadius: 6),
                              ]
                            : null,
                      ),
                      child: selected
                          ? Icon(Icons.check,
                              size: 24,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black54
                                  : Colors.white)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, DrawingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alles löschen?'),
        content: const Text('Dein Bild wird komplett leer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Nein'),
          ),
          FilledButton(
            onPressed: () {
              provider.clearAll();
              Navigator.of(ctx).pop();
            },
            child: const Text('Ja, leeren'),
          ),
        ],
      ),
    );
  }
}

/// Werkzeug-Button mit eigener Leuchtfarbe und Auswahl-Animation.
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool rainbow;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.rainbow = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg =
        selected ? Colors.white : Color.lerp(color, Colors.black, 0.25)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.08 : 1.0,
          duration: DrawingToolbar._animDuration,
          child: AnimatedContainer(
            duration: DrawingToolbar._animDuration,
            constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: rainbow
                  ? null
                  : selected
                      ? color
                      : Color.lerp(Colors.white, color, 0.18),
              borderRadius: BorderRadius.circular(22),
              gradient: rainbow
                  ? LinearGradient(
                      colors: selected
                          ? const [
                              Color(0xFFF44336),
                              Color(0xFFFF9800),
                              Color(0xFFFFEB3B),
                              Color(0xFF4CAF50),
                              Color(0xFF2196F3),
                              Color(0xFF9C27B0),
                            ]
                          : const [
                              Color(0xFFFFCDD2),
                              Color(0xFFFFF9C4),
                              Color(0xFFC8E6C9),
                              Color(0xFFBBDEFB),
                              Color(0xFFE1BEE7),
                            ])
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: color.withOpacity(0.55),
                          blurRadius: 10,
                          spreadRadius: 1),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: rainbow && !selected
                        ? const Color(0xFF5D4037)
                        : fg,
                    size: 28),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        color: rainbow && !selected
                            ? const Color(0xFF5D4037)
                            : fg,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Großer runder Aktions-Button (Undo, Leeren, Sichern, Menü).
class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool enabled;

  const _RoundActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconColor = Colors.white,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    final bg = active ? color : Colors.grey.shade400;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: bg,
            shape: const CircleBorder(),
            elevation: active ? 3 : 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: active ? onTap : null,
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(icon,
                    color: active ? iconColor : Colors.white, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Muster-Auswahl für das Füll-Werkzeug: "Nur Farbe" + 8 Muster als Kreise.
class _PatternRow extends StatelessWidget {
  final DrawingProvider provider;

  const _PatternRow(this.provider);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _patternCircle(context, null),
          for (final pattern in FillPattern.values)
            _patternCircle(context, pattern),
        ],
      ),
    );
  }

  Widget _patternCircle(BuildContext context, FillPattern? pattern) {
    final selected = provider.fillPattern == pattern;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: () => provider.setFillPattern(pattern),
        child: Tooltip(
          message: pattern == null ? 'Nur Farbe' : patternLabel(pattern),
          child: AnimatedScale(
            scale: selected ? 1.12 : 1.0,
            duration: DrawingToolbar._animDuration,
            child: AnimatedContainer(
              duration: DrawingToolbar._animDuration,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? DrawingToolbar._selectedColor
                      : Colors.black26,
                  width: selected ? 4 : 1.5,
                ),
                boxShadow: selected
                    ? const [BoxShadow(color: Colors.black26, blurRadius: 6)]
                    : null,
              ),
              child: ClipOval(
                child: pattern == null
                    ? Container(
                        color: provider.currentColor,
                        child: Icon(Icons.water_drop,
                            size: 22,
                            color: provider.currentColor.computeLuminance() >
                                    0.5
                                ? Colors.black38
                                : Colors.white70),
                      )
                    : CustomPaint(
                        painter: _PatternPreviewPainter(
                            pattern, provider.currentColor),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kleine Vorschau eines Musters im Auswahl-Kreis.
class _PatternPreviewPainter extends CustomPainter {
  final FillPattern pattern;
  final Color color;

  _PatternPreviewPainter(this.pattern, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    paintPattern(canvas, Offset.zero & size, pattern, color, tile: 16);
  }

  @override
  bool shouldRepaint(covariant _PatternPreviewPainter old) =>
      old.pattern != pattern || old.color != color;
}

/// Umschalter Felder-Modus / Frei-Modus (nur mit Vorlage sinnvoll).
class _ModeToggle extends StatelessWidget {
  final DrawingProvider provider;

  const _ModeToggle(this.provider);

  @override
  Widget build(BuildContext context) {
    final isFields = provider.mode == DrawMode.fields;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: isFields ? const Color(0xFF8E24AA) : const Color(0xFF00897B),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () =>
              provider.setMode(isFields ? DrawMode.free : DrawMode.fields),
          child: Container(
            constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isFields ? Icons.grid_on : Icons.gesture,
                    color: Colors.white, size: 28),
                const SizedBox(height: 2),
                Text(isFields ? 'Felder' : 'Frei',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slider für die Pinselgröße mit Live-Vorschau.
class _BrushSizeSlider extends StatelessWidget {
  final DrawingProvider provider;

  const _BrushSizeSlider(this.provider);

  @override
  Widget build(BuildContext context) {
    final previewColor = provider.currentTool == Tool.eraser
        ? Colors.grey
        : provider.currentColor;
    return Row(
      children: [
        const SizedBox(width: 8),
        Icon(Icons.circle, size: 10, color: Colors.brown.shade300),
        Expanded(
          child: Slider(
            value: provider.strokeWidth,
            min: DrawingProvider.minStrokeWidth,
            max: DrawingProvider.maxStrokeWidth,
            activeColor: DrawingToolbar._selectedColor,
            onChanged: provider.setStrokeWidth,
          ),
        ),
        Icon(Icons.circle, size: 26, color: Colors.brown.shade300),
        const SizedBox(width: 12),
        // Live-Vorschau der aktuellen Pinselgröße und -farbe
        SizedBox(
          width: DrawingProvider.maxStrokeWidth + 4,
          height: DrawingProvider.maxStrokeWidth + 4,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: provider.strokeWidth,
              height: provider.strokeWidth,
              decoration: BoxDecoration(
                color: previewColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
