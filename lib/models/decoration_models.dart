import 'dart:ui';

/// Dauerhaft sichtbares Dekorations-Element (Stern oder Glitzer).
class Decoration {
  final Offset position;
  final DecorationType type;
  final double size;
  final Color color;

  /// Identität des Felds, in dem die Dekoration platziert wurde (null = Freier Modus).
  final String? fieldId;

  const Decoration({
    required this.position,
    required this.type,
    this.size = 28.0,
    this.color = const Color(0xFFFFD54F),
    this.fieldId,
  });
}

enum DecorationType { star, glitter }
