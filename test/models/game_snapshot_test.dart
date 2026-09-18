import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/logic/game_logic.dart';
import 'package:block_fusion/models/block_color.dart';
import 'package:block_fusion/models/block_kind.dart';
import 'package:block_fusion/models/block_shape.dart';
import 'package:block_fusion/models/game_block.dart';
import 'package:block_fusion/models/game_snapshot.dart';
import 'package:block_fusion/models/grid_position.dart';

BlockShape _shapeById(String id) =>
    BlockShape.library.firstWhere((shape) => shape.id == id);

/// A snapshot that round-trips through JSON, the way a real save does.
GameSnapshot? _roundTrip(GameSnapshot snapshot) =>
    GameSnapshot.fromJson(_asStored(snapshot));

/// The snapshot as it comes back off disk: encoded and decoded, so the
/// lists are the untyped ones a real load works with. The corruption tests
/// need that — a typed List<int> straight from toJson() refuses a bad value
/// before the parser ever sees it, which would test nothing.
Map<String, dynamic> _asStored(GameSnapshot snapshot) =>
    jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, dynamic>;

void main() {
  group('GameSnapshot', () {
    test('a played board survives a round trip', () {
      final logic = GameLogic()
        ..grid.place(_shapeById('square'), const GridPosition(2, 3),
            BlockColor.purple)
        ..grid.placeWildcard(const GridPosition(5, 5))
        ..grid.lockCell(const GridPosition(7, 1), level: 2);

      final restored = _roundTrip(logic.toSnapshot());

      expect(restored, isNotNull);
      final board = GameLogic()..restore(restored!);
      expect(
        board.grid.cellAt(const GridPosition(2, 3)).color,
        BlockColor.purple,
      );
      expect(board.grid.cellAt(const GridPosition(5, 5)).isWildcard, isTrue);
      expect(board.grid.cellAt(const GridPosition(7, 1)).lockLevel, 2);
      expect(board.grid.cellAt(const GridPosition(0, 0)).isEmpty, isTrue);
    });

    test('the tray, score and best score survive too', () {
      final logic = GameLogic();
      logic.tryPlace(0, const GridPosition(0, 0));
      final before = logic.toSnapshot();

      final after = GameLogic()..restore(_roundTrip(before)!);

      expect(after.score, logic.score);
      expect(after.bestScore, logic.bestScore);
      expect(
        after.tray.map((block) => block?.shape.id).toList(),
        logic.tray.map((block) => block?.shape.id).toList(),
      );
    });

    test('power-up pieces come back as power-ups', () {
      final logic = GameLogic();
      // Whatever the generator dealt, force one of each into the tray.
      logic.tray[0] = GameBlock.bomb();
      logic.tray[1] = GameBlock.wildcard();

      final restored = _roundTrip(logic.toSnapshot())!;
      final after = GameLogic()..restore(restored);

      expect(after.tray[0]?.kind, BlockKind.bomb);
      expect(after.tray[1]?.kind, BlockKind.wildcard);
    });

    test('a save from another version is refused', () {
      final logic = GameLogic();
      final json = _asStored(logic.toSnapshot())..['version'] = 999;

      expect(GameSnapshot.fromJson(json), isNull);
    });

    test('a board of the wrong size is refused', () {
      final json = _asStored(GameLogic().toSnapshot());
      json['cells'] = (json['cells']! as List).sublist(0, 10);

      expect(GameSnapshot.fromJson(json), isNull);
    });

    test('a cell encoded as nonsense is refused', () {
      final json = _asStored(GameLogic().toSnapshot());
      (json['cells']! as List)[5] = 'not a cell';

      expect(GameSnapshot.fromJson(json), isNull);
    });

    test('an unparseable tray slot becomes an empty slot, not a crash', () {
      // One bad slot should cost the player one piece, not the whole save.
      final json = _asStored(GameLogic().toSnapshot());
      (json['tray']! as List)[0] = {'kind': 'no-such-kind'};

      final restored = GameSnapshot.fromJson(json);

      expect(restored, isNotNull);
      expect(restored!.tray[0], isNull);
    });

    test('restoring an empty tray deals a fresh one', () {
      // Otherwise the player is left with nothing to place and no refill
      // coming, which is a soft lock.
      final json = _asStored(GameLogic().toSnapshot());
      json['tray'] = [null, null, null];

      final after = GameLogic()..restore(GameSnapshot.fromJson(json)!);

      expect(after.tray.whereType<Object>(), isNotEmpty);
    });

    test('a best score below the current score is corrected', () {
      // The two are written together, so they can only disagree if a save
      // was tampered with or half-written.
      final json = _asStored(GameLogic().toSnapshot());
      json['score'] = 500;
      json['bestScore'] = 10;

      final after = GameLogic()..restore(GameSnapshot.fromJson(json)!);

      expect(after.bestScore, 500);
    });
  });
}
