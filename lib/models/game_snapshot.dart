import 'block_color.dart';
import 'block_kind.dart';
import 'block_shape.dart';
import 'cell.dart';
import 'game_block.dart';
import 'game_grid.dart';

/// A saved game, and the only thing that knows how one is written down.
///
/// Kept as plain data with its own encoding so the round trip can be tested
/// without a disk, a plugin or a running game.
///
/// Every `fromJson` path treats the stored value as untrusted: a save can
/// come from an older version of the game, a half-finished write, or a
/// storage backend that returned something unexpected. Anything that does
/// not parse yields `null`, and the caller starts a fresh game — losing one
/// run is a far better outcome than refusing to launch.
class GameSnapshot {
  const GameSnapshot({
    required this.cells,
    required this.tray,
    required this.score,
    required this.bestScore,
  });

  /// Bumped whenever the encoding changes; a save from another version is
  /// discarded rather than guessed at.
  static const int version = 1;

  // Cell encodings. Spread out so a new kind can be added in a gap without
  // renumbering what is already written to people's devices.
  static const int _empty = 0;
  static const int _colorBase = 1; // _colorBase + index into BlockColor.values
  static const int _wildcard = 20;
  static const int _lockBase = 30; // _lockBase + lock level

  final List<Cell> cells;
  final List<GameBlock?> tray;
  final int score;
  final int bestScore;

  Map<String, dynamic> toJson() => {
        'version': version,
        'cells': cells.map(_encodeCell).toList(),
        'tray': tray.map(_encodeBlock).toList(),
        'score': score,
        'bestScore': bestScore,
      };

  static GameSnapshot? fromJson(Map<String, dynamic> json) {
    if (json['version'] != version) return null;

    final rawCells = json['cells'];
    final rawTray = json['tray'];
    if (rawCells is! List || rawTray is! List) return null;
    if (rawCells.length != GameGrid.size * GameGrid.size) return null;

    final cells = <Cell>[];
    for (final raw in rawCells) {
      final cell = _decodeCell(raw);
      if (cell == null) return null;
      cells.add(cell);
    }

    return GameSnapshot(
      cells: cells,
      tray: [for (final raw in rawTray) _decodeBlock(raw)],
      score: json['score'] is int ? json['score'] as int : 0,
      bestScore: json['bestScore'] is int ? json['bestScore'] as int : 0,
    );
  }

  static int _encodeCell(Cell cell) {
    if (cell.isLocked) return _lockBase + cell.lockLevel;
    if (cell.isWildcard) return _wildcard;
    final color = cell.color;
    if (color == null) return _empty;
    return _colorBase + BlockColor.values.indexOf(color);
  }

  static Cell? _decodeCell(Object? raw) {
    if (raw is! int) return null;
    if (raw == _empty) return const Cell.empty();
    if (raw == _wildcard) return const Cell.wildcard();
    if (raw >= _lockBase) {
      final level = raw - _lockBase;
      return level > 0 ? Cell(lockLevel: level) : const Cell.empty();
    }
    final index = raw - _colorBase;
    if (index < 0 || index >= BlockColor.values.length) return null;
    return Cell(color: BlockColor.values[index]);
  }

  static Map<String, dynamic>? _encodeBlock(GameBlock? block) {
    if (block == null) return null;
    return {
      'shape': block.shape.id,
      'color': BlockColor.values.indexOf(block.color),
      'kind': block.kind.name,
    };
  }

  static GameBlock? _decodeBlock(Object? raw) {
    if (raw is! Map) return null;

    final kindName = raw['kind'];
    final kind = BlockKind.values.where((k) => k.name == kindName).firstOrNull;
    if (kind == null) return null;
    // The power-ups have their own constructors; their shape and colour are
    // not the player's to have changed.
    if (kind == BlockKind.bomb) return GameBlock.bomb();
    if (kind == BlockKind.wildcard) return GameBlock.wildcard();

    final shapeId = raw['shape'];
    final shape =
        BlockShape.library.where((shape) => shape.id == shapeId).firstOrNull;
    final colorIndex = raw['color'];
    if (shape == null ||
        colorIndex is! int ||
        colorIndex < 0 ||
        colorIndex >= BlockColor.values.length) {
      return null;
    }
    return GameBlock(shape: shape, color: BlockColor.values[colorIndex]);
  }
}
