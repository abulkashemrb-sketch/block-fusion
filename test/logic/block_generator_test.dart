import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/logic/block_generator.dart';
import 'package:block_fusion/models/block_kind.dart';

void main() {
  group('BlockGenerator', () {
    test('produces both normal and bomb pieces over enough draws', () {
      final generator = BlockGenerator(random: Random(1));
      final blocks = List.generate(100, (_) => generator.next());

      expect(blocks.any((block) => block.kind == BlockKind.bomb), isTrue);
      expect(blocks.any((block) => block.kind == BlockKind.normal), isTrue);
    });

    test('a bomb piece always occupies a single cell', () {
      final generator = BlockGenerator(random: Random(1));
      final bombs = List.generate(100, (_) => generator.next())
          .where((block) => block.kind == BlockKind.bomb);

      expect(bombs, isNotEmpty);
      for (final bomb in bombs) {
        expect(bomb.shape.cells.length, 1);
      }
    });
  });
}
