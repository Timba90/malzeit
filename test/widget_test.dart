import 'package:flutter_test/flutter_test.dart';
import 'package:malzeit_app/services/svg_service.dart';
import 'package:malzeit_app/models/svg_template.dart';

void main() {
  test('SVG-Parser zerlegt Dino-Vorlage in Felder', () {
    const svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300">
  <g data-layer="0">
    <circle id="feld-kopf" cx="230" cy="95" r="42" fill="#FFFFFF" stroke="#000"/>
  </g>
  <g data-layer="1">
    <rect id="feld-bauch" x="10" y="10" width="50" height="40" fill="#FFFFFF"/>
    <circle id="linie-auge" cx="242" cy="88" r="6" fill="none"/>
  </g>
</svg>
''';
    final template = SvgService().parseTemplate(
      svg,
      const TemplateInfo(name: 'Test', category: 'Test', assetPath: ''),
    );

    // 2 Felder (Auge ist fill=none -> nur Linie, kein Feld)
    expect(template.fields.length, 2);
    expect(template.layerCount, 2);
    expect(template.viewBox.width, 300);
    expect(template.fields.map((f) => f.id), containsAll(['feld-kopf', 'feld-bauch']));
    // Ebenen korrekt zugeordnet
    expect(template.fields.firstWhere((f) => f.id == 'feld-kopf').layer, 0);
    expect(template.fields.firstWhere((f) => f.id == 'feld-bauch').layer, 1);
  });

  test('Feld-Contains funktioniert für Kreis', () {
    const svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle id="feld-mitte" cx="50" cy="50" r="20" fill="#FFF"/>
</svg>
''';
    final template = SvgService().parseTemplate(
      svg,
      const TemplateInfo(name: 'T', category: 'T', assetPath: ''),
    );
    final feld = template.fields.first;
    expect(feld.contains(const Offset(50, 50)), isTrue);
    expect(feld.contains(const Offset(5, 5)), isFalse);
  });
}
