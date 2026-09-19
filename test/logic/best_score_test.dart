import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/logic/block_generator.dart';
import 'package:block_fusion/logic/game_logic.dart';
import 'package:block_fusion/models/block_color.dart';
import 'package:block_fusion/models/block_shape.dart';
import 'package:block_fusion/models/game_block.dart';
import 'package:block_fusion/models/grid_position.dart';

class _FixedGenerator extends BlockGenerator {
  _FixedGenerator(this._block);
  final GameBlock _block;

  @override
  GameBlock next({double fullness = 0}) => _block;
}

GameLogic _logicWithSingles() => GameLogic(
      generator: _FixedGenerator(
        GameBlock(
          shape: BlockShape.library.firstWhere((s) => s.id == 'single'),
          color: BlockColor.red,
        ),
      ),
    );

void main() {
  group('best score', () {
    test('tracks the highest score reached', () {
      final logic = _logicWithSingles();

      logic.tryPlace(0, const GridPosition(0, 0));
      logic.tryPlace(1, const GridPosition(0, 1));

      expect(logic.score, 2);
      expect(logic.bestScore, 2);
    });

    test('survives a restart', () {
      final logic = _logicWithSingles();
      logic.tryPlace(0, const GridPosition(0, 0));

      logic.restart();

      expect(logic.score, 0);
      expect(logic.bestScore, 1);
    });

    test('a stored best score raises the crown', () {
      final logic = _logicWithSingles();

      logic.raiseBestScore(500);

      expect(logic.bestScore, 500);
    });

    test('a stored best score never lowers one just set', () {
      // The server read arrives asynchronously, so it can land after the
      // player has already beaten it. Applying it blindly would take the
      // higher score away in front of them.
      final logic = _logicWithSingles();
      logic.raiseBestScore(500);

      logic.raiseBestScore(100);

      expect(logic.bestScore, 500);
    });

    test('raising to the same value notifies nobody', () {
      final logic = _logicWithSingles();
      logic.raiseBestScore(300);
      var notifications = 0;
      logic.addListener(() => notifications++);

      logic.raiseBestScore(300);

      expect(notifications, 0);
    });
  });
}
