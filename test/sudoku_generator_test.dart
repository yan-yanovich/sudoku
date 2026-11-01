import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/sudoku_generator.dart';

void main() {
  final generator = SudokuGenerator();

  for (final difficulty in Difficulty.values) {
    test('Генерация корректна: ${difficulty.label}', () {
      final p = generator.generate(difficulty);

      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final n = p.solution[r][c];
          // Решение заполнено и валидно
          expect(n, inInclusiveRange(1, 9));
          expect(SudokuGenerator.isValidPlacement(p.solution, r, c, n), isTrue);
          // Открытые клетки совпадают с решением
          if (p.puzzle[r][c] != 0) expect(p.puzzle[r][c], n);
        }
      }

      // Решение единственное
      final copy = copyGrid(p.puzzle);
      expect(SudokuGenerator.countSolutions(copy, limit: 2), 1);
    });
  }
}
