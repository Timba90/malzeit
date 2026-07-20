import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:malzeit_app/services/svg_service.dart';
import 'package:malzeit_app/models/svg_template.dart';

void main() {
  final cases = {
    'assets/svg/templates/dinos/dino.svg': 5,
    'assets/svg/templates/autos/auto.svg': 7,
    'assets/svg/templates/schlangen/schlange.svg': 5,
    'assets/svg/templates/blumen/blume.svg': 10,
  };
  cases.forEach((path, expectedFields) {
    test('$path -> $expectedFields Felder', () {
      final raw = File(path).readAsStringSync();
      final t = SvgService().parseTemplate(
        raw,
        TemplateInfo(name: path, category: 'c', assetPath: path),
      );
      expect(t.fields.length, expectedFields,
          reason: 'Felder: ${t.fields.map((f) => f.id).join(", ")}');
      expect(t.layerCount, greaterThanOrEqualTo(2));
    });
  });
}
