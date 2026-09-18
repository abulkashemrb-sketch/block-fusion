import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/logic/block_generator.dart';
import 'package:block_fusion/models/block_kind.dart';
import 'package:block_fusion/models/game_block.dart';

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

    test('without a fit check the tray is drawn purely at random', () {
      final generator = BlockGenerator(random: Random(3));

      final tray = generator.nextTray();

      expect(tray, hasLength(3));
    });

    test('nextTray always includes a piece the fit check accepts', () {
      final generator = BlockGenerator(random: Random(3));
      // The harshest board there is: only a one-cell piece would fit.
      bool onlySingles(GameBlock block) => block.shape.cells.length == 1;

      for (var draw = 0; draw < 50; draw++) {
        final tray = generator.nextTray(fits: onlySingles);

        expect(tray, hasLength(3));
        expect(tray.any(onlySingles), isTrue);
      }
    });

    test('nextTray gives up gracefully when nothing can fit', () {
      final generator = BlockGenerator(random: Random(3));

      // A board with no legal move at all is a real game over, so the
      // generator must deal a normal tray rather than invent a move.
      final tray = generator.nextTray(fits: (_) => false);

      expect(tray, hasLength(3));
    });
  });
}
