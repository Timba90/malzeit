import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/drawing_provider.dart';

/// Untere Werkzeugleiste: Werkzeuge, Farben, Aktionen.
/// Kindgerecht: große Buttons, klare Symbole, keine Text-Menüs.
class DrawingToolbar extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onBack;

  const DrawingToolbar({super.key, this.onSave, this.onBack});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DrawingProvider>();

    return Container(
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zeile 1: Werkzeuge + Modus + Aktionen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolButton(
                context,
                icon: Icons.brush,
                label: 'Pinsel',
                selected: provider.currentTool == Tool.brush,
                onTap: () => provider.setTool(Tool.brush),
              ),
              _toolButton(
                context,
                icon: Icons.auto_fix_off,
                label: 'Radierer',
                selected: provider.currentTool == Tool.eraser,
                onTap: () => provider.setTool(Tool.eraser),
              ),
              _toolButton(
                context,
                icon: Icons.star,
                label: 'Sterne',
                selected: provider.currentTool == Tool.star,
                onTap: () => provider.setTool(Tool.star),
              ),
              _toolButton(
                context,
                icon: Icons.auto_awesome,
                label: 'Glitzer',
                selected: provider.currentTool == Tool.glitter,
                onTap: () => provider.setTool(Tool.glitter),
              ),
              _modeToggle(context, provider),
              _actionButton(
                icon: Icons.delete_outline,
                label: 'Leeren',
                color: const Color(0xFFE53935),
                onTap: () => _confirmClear(context, provider),
              ),
              if (onSave != null)
                _actionButton(
                  icon: Icons.save_alt,
                  label: 'Sichern',
                  color: const Color(0xFF43A047),
                  onTap: onSave!,
                ),
              if (onBack != null)
                _actionButton(
                  icon: Icons.arrow_back,
                  label: 'Zurück',
                  color: const Color(0xFF1E88E5),
                  onTap: onBack!,
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Zeile 2: Farbpalette
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: DrawingProvider.palette.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final color = DrawingProvider.palette[i];
                final selected = provider.currentColor.value == color.value &&
                    provider.currentTool != Tool.eraser;
                return GestureDetector(
                  onTap: () => provider.setColor(color),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1E88E5)
                            : Colors.black26,
                        width: selected ? 4 : 1.5,
                      ),
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

  Widget _toolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _baseButton(
      icon: icon,
      label: label,
      background:
          selected ? const Color(0xFF1E88E5) : const Color(0xFFFFE0B2),
      foreground: selected ? Colors.white : const Color(0xFF5D4037),
      onTap: onTap,
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _baseButton(
      icon: icon,
      label: label,
      background: color,
      foreground: Colors.white,
      onTap: onTap,
    );
  }

  Widget _baseButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 26),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeToggle(BuildContext context, DrawingProvider provider) {
    final isFields = provider.mode == DrawMode.fields;
    return Material(
      color: isFields ? const Color(0xFF8E24AA) : const Color(0xFF00897B),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => provider
            .setMode(isFields ? DrawMode.free : DrawMode.fields),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isFields ? Icons.grid_on : Icons.gesture,
                  color: Colors.white, size: 26),
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
