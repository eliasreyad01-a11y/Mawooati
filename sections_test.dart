import 'package:flutter_test/flutter_test.dart';
import 'package:mawoonati/core/sections.dart';

void main() {
  test('section ids are unique', () {
    final ids = sections.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
  });
  test('every unbuilt section maps to a known phase 2..9', () {
    for (final s in sections.where((s) => !s.isBuilt)) {
      expect(phaseNames.containsKey(s.phase), isTrue, reason: s.id);
      expect(s.phase, inInclusiveRange(2, 9), reason: s.id);
    }
  });
  test('quick actions all exist', () {
    for (final id in quickActionIds) {
      expect(() => sectionById(id), returnsNormally);
    }
  });
}
