import 'dart:math';

enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Лёгкий',
        Difficulty.medium => 'Средний',
        Difficulty.hard => 'Сложный',
      };

  /// Сколько клеток пытаемся убрать из заполненной сетки.
  int get cellsToRemove => switch (this) {
        Difficulty.easy => 36,
        Difficulty.medium => 46,
        Difficulty.hard => 54,
      };
}

class SudokuPuzzle {
  final List<List<int>> puzzle; // 0 = пустая клетка
  final List<List<int>> solution;

  const SudokuPuzzle({required this.puzzle, required this.solution});
}

class SudokuGenerator {
  final Random _random;

  SudokuGenerator([Random? random]) : _random = random ?? Random();

  SudokuPuzzle generate(Difficulty difficulty) {
    // 1. Строим полностью заполненную корректную сетку.
    final solution = List.generate(9, (_) => List.filled(9, 0));
    _fillGrid(solution);

    // 2. Убираем клетки, пока решение остаётся единственным.
    final puzzle = copyGrid(solution);
    final positions = List.generate(81, (i) => i)..shuffle(_random);

    var removed = 0;
    for (final pos in positions) {
      if (removed >= difficulty.cellsToRemove) break;
      final r = pos ~/ 9;
      final c = pos % 9;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;

      if (countSolutions(puzzle, limit: 2) != 1) {
        puzzle[r][c] = backup; // решение перестало быть единственным
      } else {
        removed++;
      }
    }

    return SudokuPuzzle(puzzle: puzzle, solution: solution);
  }

  /// Заполняет сетку случайным корректным решением (backtracking).
  bool _fillGrid(List<List<int>> grid) {
    for (var i = 0; i < 81; i++) {
      final r = i ~/ 9;
      final c = i % 9;
      if (grid[r][c] != 0) continue;

      final numbers = List.generate(9, (n) => n + 1)..shuffle(_random);
      for (final n in numbers) {
        if (isValidPlacement(grid, r, c, n)) {
          grid[r][c] = n;
          if (_fillGrid(grid)) return true;
          grid[r][c] = 0;
        }
      }
      return false;
    }
    return true;
  }

  /// Считает количество решений, но не больше [limit].
  static int countSolutions(List<List<int>> grid, {int limit = 2}) {
    for (var i = 0; i < 81; i++) {
      final r = i ~/ 9;
      final c = i % 9;
      if (grid[r][c] != 0) continue;

      var count = 0;
      for (var n = 1; n <= 9; n++) {
        if (isValidPlacement(grid, r, c, n)) {
          grid[r][c] = n;
          count += countSolutions(grid, limit: limit - count);
          grid[r][c] = 0;
          if (count >= limit) return count;
        }
      }
      return count;
    }
    return 1; // пустых клеток нет, значит найдено одно решение
  }

  /// Можно ли поставить [num] в клетку (row, col).
  static bool isValidPlacement(List<List<int>> grid, int row, int col, int num) {
    for (var i = 0; i < 9; i++) {
      if (i != col && grid[row][i] == num) return false;
      if (i != row && grid[i][col] == num) return false;
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if ((r != row || c != col) && grid[r][c] == num) return false;
      }
    }
    return true;
  }
}

/// Копия сетки 9×9.
List<List<int>> copyGrid(List<List<int>> grid) =>
    grid.map((row) => List<int>.from(row)).toList();

/// Точка входа для compute(): генерация в отдельном изоляте,
/// чтобы интерфейс не тормозил.
SudokuPuzzle generatePuzzle(Difficulty difficulty) =>
    SudokuGenerator().generate(difficulty);
