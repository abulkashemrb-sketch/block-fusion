import 'grid_position.dart';

/// A fixed polyomino shape a tray piece can take.
///
/// Shapes have no rotation — every orientation that should be playable is
/// listed as its own entry in [library], matching the reference game this
/// project is modeled after.
class BlockShape {
  const BlockShape({
    required this.id,
    required this.cells,
    required this.width,
    required this.height,
  });

  final String id;

  /// Cell offsets relative to the shape's own top-left bounding corner.
  final List<GridPosition> cells;
  final int width;
  final int height;

  static const List<BlockShape> library = [
    BlockShape(id: 'single', width: 1, height: 1, cells: [
      GridPosition(0, 0),
    ]),
    BlockShape(id: 'domino_h', width: 2, height: 1, cells: [
      GridPosition(0, 0), GridPosition(0, 1),
    ]),
    BlockShape(id: 'domino_v', width: 1, height: 2, cells: [
      GridPosition(0, 0), GridPosition(1, 0),
    ]),
    BlockShape(id: 'tromino_h', width: 3, height: 1, cells: [
      GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2),
    ]),
    BlockShape(id: 'tromino_v', width: 1, height: 3, cells: [
      GridPosition(0, 0), GridPosition(1, 0), GridPosition(2, 0),
    ]),
    BlockShape(id: 'corner_tl', width: 2, height: 2, cells: [
      GridPosition(0, 0), GridPosition(0, 1), GridPosition(1, 0),
    ]),
    BlockShape(id: 'corner_tr', width: 2, height: 2, cells: [
      GridPosition(0, 0), GridPosition(0, 1), GridPosition(1, 1),
    ]),
    BlockShape(id: 'corner_bl', width: 2, height: 2, cells: [
      GridPosition(0, 0), GridPosition(1, 0), GridPosition(1, 1),
    ]),
    BlockShape(id: 'corner_br', width: 2, height: 2, cells: [
      GridPosition(0, 1), GridPosition(1, 0), GridPosition(1, 1),
    ]),
    BlockShape(id: 'square', width: 2, height: 2, cells: [
      GridPosition(0, 0), GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 1),
    ]),
    BlockShape(id: 'tetra_i_h', width: 4, height: 1, cells: [
      GridPosition(0, 0), GridPosition(0, 1),
      GridPosition(0, 2), GridPosition(0, 3),
    ]),
    BlockShape(id: 'tetra_i_v', width: 1, height: 4, cells: [
      GridPosition(0, 0), GridPosition(1, 0),
      GridPosition(2, 0), GridPosition(3, 0),
    ]),
    BlockShape(id: 'tetra_l', width: 2, height: 3, cells: [
      GridPosition(0, 0), GridPosition(1, 0),
      GridPosition(2, 0), GridPosition(2, 1),
    ]),
    BlockShape(id: 'tetra_j', width: 2, height: 3, cells: [
      GridPosition(0, 1), GridPosition(1, 1),
      GridPosition(2, 0), GridPosition(2, 1),
    ]),
    BlockShape(id: 'tetra_t', width: 3, height: 2, cells: [
      GridPosition(0, 0), GridPosition(0, 1),
      GridPosition(0, 2), GridPosition(1, 1),
    ]),
    BlockShape(id: 'tetra_s', width: 3, height: 2, cells: [
      GridPosition(0, 1), GridPosition(0, 2),
      GridPosition(1, 0), GridPosition(1, 1),
    ]),
    BlockShape(id: 'tetra_z', width: 3, height: 2, cells: [
      GridPosition(0, 0), GridPosition(0, 1),
      GridPosition(1, 1), GridPosition(1, 2),
    ]),
    BlockShape(id: 'penta_plus', width: 3, height: 3, cells: [
      GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 1), GridPosition(1, 2),
      GridPosition(2, 1),
    ]),
  ];
}
