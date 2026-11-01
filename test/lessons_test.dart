import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/sudoku_generator.dart';
import 'package:sudoku/tutorial/lesson_data.dart';

final _solvedRow = RegExp(r'^[1-9]{9}$');
final _puzzleRow = RegExp(r'^[1-9.]{9}$');
final _maskRow = RegExp(r'^[x.]{9}$');

/// Нет ли повторов среди заполненных клеток.
void _expectNoConflicts(List<List<int>> grid, String where) {
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      final v = grid[r][c];
      if (v == 0) continue;
      expect(SudokuGenerator.isValidPlacement(grid, r, c, v), isTrue,
          reason: '$where: повтор цифры $v в клетке (${r + 1}, ${c + 1})');
    }
  }
}

void main() {
  group('baseSolution', () {
    test('9 строк по 9 цифр, без заглушек', () {
      expect(baseSolution.length, 9);
      for (final (i, row) in baseSolution.indexed) {
        expect(_solvedRow.hasMatch(row), isTrue,
            reason: 'Строка ${i + 1}: "$row" — должно быть 9 цифр 1–9');
      }
    });

    test('Корректное решённое судоку', () {
      final grid = parseRows(baseSolution);
      _expectNoConflicts(grid, 'baseSolution');
    });

    test('Согласовано с wikiPuzzle', () {
      final sol = parseRows(baseSolution);
      final puz = parseRows(wikiPuzzle);
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (puz[r][c] != 0) {
            expect(sol[r][c], puz[r][c],
                reason: 'Клетка (${r + 1}, ${c + 1})');
          }
        }
      }
    });

    test('wikiMask совпадает с подсказками wikiPuzzle', () {
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(wikiMask[r][c] == 'x', wikiPuzzle[r][c] != '.',
              reason: 'Клетка (${r + 1}, ${c + 1})');
        }
      }
    });
  });

  group('Уроки', () {
    test('Всего 18 уроков, id уникальны', () {
      expect(allLessons.length, 18);
      final ids = allLessons.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'Повторяющиеся id');
    });

    for (final lesson in allLessons) {
      group(lesson.id, () {
        test('Тексты заполнены', () {
          expect(lesson.title.trim(), isNotEmpty);
          expect(lesson.theory.trim(), isNotEmpty);
          expect(lesson.example.caption.trim(), isNotEmpty);
          expect(lesson.practice.task.trim(), isNotEmpty);
        });

        test('Пример: корректное поле и разметка', () {
          final rows = lesson.example.rows;
          expect(rows.length, 9);
          for (final row in rows) {
            expect(_puzzleRow.hasMatch(row), isTrue, reason: '"$row"');
          }
          _expectNoConflicts(lesson.example.board, 'пример');

          for (final m in lesson.example.marks) {
            expect(m.row, inInclusiveRange(0, 8));
            expect(m.col, inInclusiveRange(0, 8));
            for (final n in m.notes ?? const <int>[]) {
              expect(n, inInclusiveRange(1, 9));
            }
          }
        });

        test('Практика: маска, перестановка, единственное решение', () {
          final p = lesson.practice;

          expect(p.mask.length, 9);
          for (final row in p.mask) {
            expect(_maskRow.hasMatch(row), isTrue, reason: 'Маска "$row"');
          }

          final relabel = p.relabel.split('')..sort();
          expect(relabel.join(), '123456789',
              reason: 'relabel должен быть перестановкой цифр 1–9');

          final solution = p.solution;
          _expectNoConflicts(solution, 'решение практики');

          final puzzle = p.puzzle;
          for (var r = 0; r < 9; r++) {
            for (var c = 0; c < 9; c++) {
              if (puzzle[r][c] != 0) expect(puzzle[r][c], solution[r][c]);
            }
          }

          expect(
            SudokuGenerator.countSolutions(copyGrid(puzzle), limit: 2),
            1,
            reason: 'У практики должно быть ровно одно решение',
          );
        });
      });
    }
  });
}
