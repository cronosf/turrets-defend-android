import 'package:flame/components.dart';

import 'components/turret_component.dart';

/// Geometry + occupancy bookkeeping for the merge/defense grid. Turrets both
/// live and fight from these slots (matching the reference kit: the grid at
/// the bottom of the field is simultaneously the merge board and the firing
/// line), so there is a single grid rather than a separate inventory strip.
class TurretGrid {
  static const int rows = 3;
  static const int cols = 5;
  static const double slotSize = 56;
  static const double gap = 8;

  /// Row 0 (the bonus row above the two main ones) only has 3 usable slots,
  /// centered within the 5-wide grid by simply only using columns 1-3 of
  /// the same coordinate space every other row uses — no separate centering
  /// math needed. Columns 0 and 4 of row 0 are never placed into, never
  /// rendered, and never a valid drop target.
  static bool isUsable(int row, int col) {
    if (row == 0) return col >= 1 && col <= 3;
    return true;
  }

  late Vector2 topLeft;
  final List<List<TurretComponent?>> _occupancy =
      List.generate(rows, (_) => List<TurretComponent?>.filled(cols, null));

  void layout(Vector2 fieldSize) {
    final gridWidth = cols * slotSize + (cols - 1) * gap;
    final x = (fieldSize.x - gridWidth) / 2;
    final y = fieldSize.y - rows * slotSize - (rows - 1) * gap - 24;
    topLeft = Vector2(x, y);
  }

  Vector2 slotCenter(int row, int col) {
    return Vector2(
      topLeft.x + col * (slotSize + gap) + slotSize / 2,
      topLeft.y + row * (slotSize + gap) + slotSize / 2,
    );
  }

  double get topY => topLeft.y;

  TurretComponent? at(int row, int col) => _occupancy[row][col];

  bool isEmpty(int row, int col) => _occupancy[row][col] == null;

  void place(TurretComponent turret, int row, int col) {
    _occupancy[row][col] = turret;
    turret.row = row;
    turret.col = col;
    turret.position = slotCenter(row, col);
  }

  void clear(int row, int col) {
    _occupancy[row][col] = null;
  }

  ({int row, int col})? firstEmptySlot() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!isUsable(r, c)) continue;
        if (_occupancy[r][c] == null) return (row: r, col: c);
      }
    }
    return null;
  }

  /// Finds the usable slot whose center is nearest to [point], regardless
  /// of whether it's occupied (used while dragging to decide the drop
  /// target).
  ({int row, int col}) nearestSlot(Vector2 point) {
    var bestRow = 1;
    var bestCol = 0;
    var bestDist = double.infinity;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!isUsable(r, c)) continue;
        final d = slotCenter(r, c).distanceToSquared(point);
        if (d < bestDist) {
          bestDist = d;
          bestRow = r;
          bestCol = c;
        }
      }
    }
    return (row: bestRow, col: bestCol);
  }

  List<TurretComponent> get allTurrets =>
      _occupancy.expand((row) => row).whereType<TurretComponent>().toList();
}
