import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/sudoku_generator.dart';
import 'package:sudoku/tutorial/lesson_data.dart';

void main() {
  test('baseSolution заполнено корректно', () {
    final grid = parseRows(baseSolution);
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final n = grid[r][c];
        expect(n, inInclusiveRange(1, 9));
        expect(SudokuGenerator.isValidPlacement(grid, r, c, n), isTrue);
      }
    }
  });

  test('В каждом уроке решение единственное', () {
    for (final lesson in allLessons) {
      final puzzle = copyGrid(lesson.practice.puzzle);
      final solutionCount = SudokuGenerator.countSolutions(puzzle, limit: 2);
      expect(solutionCount, 1,
          reason: 'Урок ${lesson.id}: решений $solutionCount, ожидалось 1');
    }
  });

  test('Решения уроков корректные', () {
    for (final lesson in allLessons) {
      final solution = lesson.practice.solution;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final n = solution[r][c];
          expect(n, inInclusiveRange(1, 9),
              reason: 'Урок ${lesson.id}: в решении ($r,$c) стоит $n');
          expect(SudokuGenerator.isValidPlacement(solution, r, c, n), isTrue,
              reason: 'Урок ${lesson.id}: решение невалидно в ($r,$c)');
        }
      }
    }
  });

  test('Puzzle соответствует solution', () {
    for (final lesson in allLessons) {
      final puzzle = lesson.practice.puzzle;
      final solution = lesson.practice.solution;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (puzzle[r][c] != 0) {
            expect(puzzle[r][c], solution[r][c],
                reason:
                    'Урок ${lesson.id}: подсказка в ($r,$c) не совпадает с решением');
          }
        }
      }
    }
  });
}
