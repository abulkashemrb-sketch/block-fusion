import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../logic/game_logic.dart';
import '../../models/game_grid.dart';
import '../../models/grid_position.dart';
import '../../theme/app_theme.dart';
import '../block_palette.dart';

/// Renders the 8x8 board and an optional placement preview overlay.
class GridComponent extends PositionComponent {
  GridComponent({required this.logic});

  /// How far the panel extends beyond the cell area, as a fraction of a
  /// cell, so blocks do not touch its rounded corners.
  ///
  /// It grows *outward* from the component instead of inset: cell (0, 0)
  /// has to stay at local (0, 0), because that is the origin
  /// [BlockPieceComponent] measures drops against.
  static const double _panelPadding = 0.22;

  static const int _starCount = 26;
  static const int _starSeed = 918;

  /// Height reserved at the top for the score HUD, as a fraction of the
  /// canvas.
  static const double _hudBand = 0.13;

  /// Total horizontal margin around the board.
  static const double _sideMargin = 20;

  /// How big a tray piece's cell is relative to a board cell. Tray pieces
  /// are smaller so three of them fit across; each grows to full board scale
  /// while it is dragged.
  static const double trayScale = 0.72;

  /// The tallest shape in the library, in cells — what the tray strip has to
  /// be able to hold.
  static const int _tallestShapeCells = 4;

  /// Height of the tray strip, in board cells: the tallest piece plus a
  /// little room. Derived from [trayScale] so the two cannot fall out of
  /// step.
  static const double _trayBandCells =
      _tallestShapeCells * trayScale + 0.25;

  /// Gap between the bottom of the board and the top of the tray strip.
  static const double _boardToTrayGapCells = 0.6;

  final GameLogic logic;

  double cellSize = 0;

  /// The cell size tray pieces rest at.
  double get trayCellSize => cellSize * trayScale;

  /// Vertical centre of the tray strip.
  ///
  /// Derived here rather than from a fraction of the canvas so the board and
  /// the tray cannot drift apart: on a tall phone the board is bound by
  /// width, and any fixed tray fraction leaves the whole leftover height
  /// pooled in the gap between them.
  double trayCenterY = 0;

  Set<GridPosition> _previewCells = {};
  bool _previewValid = false;
  List<Offset> _stars = const [];

  void layout(Vector2 canvasSize) {
    const gridSize = GameGrid.size;
    final maxWidth = canvasSize.x - _sideMargin;
    final maxHeight = canvasSize.y * 0.55;
    cellSize = (maxWidth < maxHeight ? maxWidth : maxHeight) / gridSize;
    size = Vector2.all(cellSize * gridSize);

    // Board and tray are laid out as one block and centred together in the
    // space under the HUD, so leftover height is split above and below them
    // instead of collecting in the middle.
    final hudBand = canvasSize.y * _hudBand;
    final trayBand = cellSize * _trayBandCells;
    final gap = cellSize * _boardToTrayGapCells;
    final slack = canvasSize.y - hudBand - size.y - gap - trayBand;
    final top = hudBand + (slack > 0 ? slack / 2 : 0);

    position = Vector2((canvasSize.x - size.x) / 2, top);
    trayCenterY = top + size.y + gap + trayBand / 2;
    _generateStars();
  }

  /// Faint specks inside the board panel, fixed per layout so they do not
  /// crawl between frames.
  void _generateStars() {
    final random = Random(_starSeed);
    _stars = [
      for (var i = 0; i < _starCount; i++)
        Offset(
          -_padding + random.nextDouble() * (size.x + _padding * 2),
          -_padding + random.nextDouble() * (size.y + _padding * 2),
        ),
    ];
  }

  /// Highlights the cells [shapeCells] (relative offsets) would occupy if
  /// anchored at [origin], colored by whether that placement is [valid].
  void setPreview(
    GridPosition origin,
    Iterable<GridPosition> shapeCells,
    bool valid,
  ) {
    _previewCells = shapeCells.map((offset) => origin + offset).toSet();
    _previewValid = valid;
  }

  void clearPreview() {
    _previewCells = {};
  }

  double get _padding => cellSize * _panelPadding;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _paintPanel(canvas);

    for (var row = 0; row < GameGrid.size; row++) {
      for (var col = 0; col < GameGrid.size; col++) {
        final position = GridPosition(row, col);
        final cell = logic.grid.cellAt(position);
        final rect = _rectFor(row, col);

        if (cell.isLocked) {
          _paintLockedCell(canvas, rect, cell.lockLevel);
        } else if (cell.isWildcard) {
          paintWildcardCell(canvas, rect);
        } else if (cell.isFilled) {
          paintBlockCell(canvas, rect, blockColorToColor(cell.color!));
        } else {
          _paintEmptyCell(canvas, rect);
        }

        if (cell.isEmpty && _previewCells.contains(position)) {
          _paintPreview(canvas, rect);
        }
      }
    }
  }

  Rect _rectFor(int row, int col) => Rect.fromLTWH(
        col * cellSize,
        row * cellSize,
        cellSize,
        cellSize,
      ).deflate(cellSize * 0.06);

  void _paintPanel(Canvas canvas) {
    final panel = Rect.fromLTWH(
      -_padding,
      -_padding,
      size.x + _padding * 2,
      size.y + _padding * 2,
    );
    final rrect = RRect.fromRectAndRadius(
      panel,
      Radius.circular(cellSize * 0.5),
    );

    canvas
      ..drawRRect(rrect, Paint()..color = AppTheme.boardPanel)
      ..save()
      ..clipRRect(rrect);
    for (final star in _stars) {
      canvas.drawCircle(
        star,
        0.9,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    }
    canvas
      ..restore()
      ..drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
  }

  void _paintEmptyCell(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide * 0.26)),
      Paint()..color = AppTheme.boardCell,
    );
  }

  /// The drop target, drawn as an outline rather than a fill so the board
  /// underneath stays readable while the piece hovers.
  void _paintPreview(Canvas canvas, Rect rect) {
    final color = _previewValid ? Colors.white : const Color(0xFFFF6B6B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide * 0.26)),
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.shortestSide * 0.09,
    );
  }

  static const _lockedFill = Color(0xFF4B6E93);
  static const _lockedBorder = Color(0xFFBBE3FF);

  void _paintLockedCell(Canvas canvas, Rect rect, int lockLevel) {
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide * 0.26));
    canvas
      ..drawRRect(rrect, Paint()..color = _lockedFill)
      ..drawRRect(
        rrect,
        Paint()
          ..color = _lockedBorder.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = rect.shortestSide * 0.08,
      );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$lockLevel',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: rect.shortestSide * 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      rect.center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}
