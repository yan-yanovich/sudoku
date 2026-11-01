import 'dart:math';

import 'sudoku_solver.dart';

enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Лёгкий',
        Difficulty.medium => 'Средний',
        Difficulty.hard => 'Сложный',
      };

  /// Целевая оценка сложности (по техникам).
  (int min, int max) get targetScore => switch (this) {
        Difficulty.easy => (1, 1),    // только голые одиночки
        Difficulty.medium => (2, 2),  // нужны скрытые одиночки
        Difficulty.hard => (3, 10),   // пары или угадывание
      };
}

class SudokuPuzzle {
  const SudokuPuzzle({required this.puzzle, required this.solution});

  final List<List<int>> puzzle;
  final List<List<int>> solution;
}

class SudokuGenerator {
  SudokuGenerator([Random? random]) : _random = random ?? Random();

  final Random _random;

  /// Генерировать головоломку заданной сложности.
  SudokuPuzzle generate(Difficulty difficulty) {
    const maxAttempts = 50;
    final target = difficulty.targetScore;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final solution = _generateSolution();
      final puzzle = _createPuzzle(solution);
      final score = rateDifficulty(puzzle);

      if (score >= target.$1 && score <= target.$2) {
        return SudokuPuzzle(puzzle: puzzle, solution: solution);
      }
    }

    // Не удалось подобрать — возвращаем последнюю попытку
    final solution = _generateSolution();
    final puzzle = _createPuzzle(solution);
    return SudokuPuzzle(puzzle: puzzle, solution: solution);
  }

  List<List<int>> _generateSolution() {
    final grid = List.generate(9, (_) => List.filled(9, 0));
    _fillGrid(grid);
    return grid;
  }

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

  /// Создать головоломку из решения, удаляя клетки с сохранением единственности.
  List<List<int>> _createPuzzle(List<List<int>> solution) {
    final puzzle = copyGrid(solution);
    final positions = List.generate(81, (i) => i)..shuffle(_random);

    // Удаляем симметричные пары для более красивого паттерна
    for (var i = 0; i < positions.length ~/ 2; i++) {
      final pos1 = positions[i];
      final pos2 = 80 - pos1; // симметричная клетка

      final r1 = pos1 ~/ 9, c1 = pos1 % 9;
      final r2 = pos2 ~/ 9, c2 = pos2 % 9;

      final backup1 = puzzle[r1][c1];
      final backup2 = puzzle[r2][c2];

      puzzle[r1][c1] = 0;
      if (r1 != r2 || c1 != c2) puzzle[r2][c2] = 0;

      if (countSolutionsFast(puzzle, limit: 2) != 1) {
        puzzle[r1][c1] = backup1;
        puzzle[r2][c2] = backup2;
      }
    }

    return puzzle;
  }

  /// Быстрый подсчёт решений с битовыми масками и MRV.
  static int countSolutionsFast(List<List<int>> grid, {int limit = 2}) {
    final rowMask = List.filled(9, 0);
    final colMask = List.filled(9, 0);
    final boxMask = List.filled(9, 0);

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final v = grid[r][c];
        if (v != 0) {
          final bit = 1 << v;
          rowMask[r] |= bit;
          colMask[c] |= bit;
          boxMask[r ~/ 3 * 3 + c ~/ 3] |= bit;
        }
      }
    }

    return _countSolutionsRec(grid, rowMask, colMask, boxMask, limit);
  }

  static int _countSolutionsRec(
    List<List<int>> grid,
    List<int> rowMask,
    List<int> colMask,
    List<int> boxMask,
    int limit,
  ) {
    if (limit == 0) return 0;

    // MRV: выбираем клетку с минимальным числом кандидатов
    int minCandidates = 10;
    int bestR = -1, bestC = -1;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (grid[r][c] != 0) continue;
        final box = r ~/ 3 * 3 + c ~/ 3;
        final used = rowMask[r] | colMask[c] | boxMask[box];
        final available = ~used & 0x3FE; // биты 1..9
        final count = available.bitCount;

        if (count == 0) return 0; // нет кандидатов — тупик
        if (count < minCandidates) {
          minCandidates = count;
          bestR = r;
          bestC = c;
        }
      }
    }

    if (bestR == -1) return 1; // все заполнены

    final r = bestR;
    final c = bestC;
    final box = r ~/ 3 * 3 + c ~/ 3;
    final used = rowMask[r] | colMask[c] | boxMask[box];

    var count = 0;
    for (var n = 1; n <= 9; n++) {
      final bit = 1 << n;
      if (used & bit != 0) continue;

      grid[r][c] = n;
      rowMask[r] |= bit;
      colMask[c] |= bit;
      boxMask[box] |= bit;

      count += _countSolutionsRec(grid, rowMask, colMask, boxMask, limit - count);

      grid[r][c] = 0;
      rowMask[r] &= ~bit;
      colMask[c] &= ~bit;
      boxMask[box] &= ~bit;

      if (count >= limit) return count;
    }

    return count;
  }

  /// Старый медленный countSolutions (для сравнения в тестах).
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
    return 1;
  }

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

List<List<int>> copyGrid(List<List<int>> grid) =>
    grid.map((row) => List<int>.from(row)).toList();

SudokuPuzzle generatePuzzle(Difficulty difficulty) =>
    SudokuGenerator().generate(difficulty);
