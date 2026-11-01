import 'sudoku_generator.dart';

/// Техника решения судоку.
enum SolveTechnique {
  nakedSingle,   // голая одиночка: в клетке один кандидат
  hiddenSingle,  // скрытая одиночка: цифра в unit стоит только здесь
  guessing;      // логика не помогла, пришлось угадывать

  int get difficulty => switch (this) {
        nakedSingle => 1,
        hiddenSingle => 2,
        guessing => 10,
      };
}

/// Результат попытки решить судоку логически.
class SolveResult {
  const SolveResult({
    required this.solved,
    required this.hardestTechnique,
    required this.stepCount,
  });

  final bool solved;
  final SolveTechnique? hardestTechnique;
  final int stepCount;

  int get difficultyScore => hardestTechnique?.difficulty ?? 0;
}

/// Логический решатель судоку (без угадывания).
class SudokuSolver {
  SudokuSolver(List<List<int>> puzzle)
      : grid = copyGrid(puzzle),
        candidates = _initCandidates(puzzle);

  final List<List<int>> grid;
  final List<List<Set<int>>> candidates;

  static List<List<Set<int>>> _initCandidates(List<List<int>> puzzle) {
    final cands = List.generate(9, (_) => List.generate(9, (_) => <int>{1, 2, 3, 4, 5, 6, 7, 8, 9}));
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (puzzle[r][c] != 0) {
          cands[r][c].clear();
          _eliminate(cands, r, c, puzzle[r][c]);
        }
      }
    }
    return cands;
  }

  static void _eliminate(List<List<Set<int>>> cands, int row, int col, int digit) {
    for (var i = 0; i < 9; i++) {
      cands[row][i].remove(digit);
      cands[i][col].remove(digit);
    }
    final br = row ~/ 3 * 3;
    final bc = col ~/ 3 * 3;
    for (var r = br; r < br + 3; r++) {
      for (var c = bc; c < bc + 3; c++) {
        cands[r][c].remove(digit);
      }
    }
  }

  /// Решить судоку, применяя только логические техники.
  SolveResult solve({int maxSteps = 100}) {
    SolveTechnique? hardest;
    var steps = 0;

    while (steps < maxSteps) {
      final technique = _step();
      if (technique == null) break;
      hardest = (hardest == null || technique.difficulty > hardest.difficulty) ? technique : hardest;
      steps++;
    }

    final solved = grid.every((row) => row.every((v) => v != 0));
    return SolveResult(solved: solved, hardestTechnique: hardest, stepCount: steps);
  }

  SolveTechnique? _step() {
    // 1. Голые одиночки
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (grid[r][c] == 0 && candidates[r][c].length == 1) {
          _place(r, c, candidates[r][c].first);
          return SolveTechnique.nakedSingle;
        }
      }
    }

    // 2. Скрытые одиночки
    for (var unit in _allUnits) {
      for (var digit = 1; digit <= 9; digit++) {
        final positions = [
          for (final (r, c) in unit)
            if (grid[r][c] == 0 && candidates[r][c].contains(digit)) (r, c),
        ];
        if (positions.length == 1) {
          final (r, c) = positions.first;
          _place(r, c, digit);
          return SolveTechnique.hiddenSingle;
        }
      }
    }

    return null; // застряли
  }

  void _place(int r, int c, int digit) {
    grid[r][c] = digit;
    candidates[r][c].clear();
    _eliminate(candidates, r, c, digit);
  }

  static final List<List<(int, int)>> _allUnits = [
    for (var r = 0; r < 9; r++) [for (var c = 0; c < 9; c++) (r, c)], // строки
    for (var c = 0; c < 9; c++) [for (var r = 0; r < 9; r++) (r, c)], // столбцы
    for (var b = 0; b < 9; b++)
      [for (var i = 0; i < 9; i++) (b ~/ 3 * 3 + i ~/ 3, b % 3 * 3 + i % 3)], // квадраты
  ];
}

/// Оценить сложность головоломки: 1 (легко) … 10 (угадывание).
int rateDifficulty(List<List<int>> puzzle) {
  final result = SudokuSolver(puzzle).solve();
  if (!result.solved) {
    // Логика не помогла — нужно угадывание
    return SolveTechnique.guessing.difficulty;
  }
  return result.difficultyScore;
}
