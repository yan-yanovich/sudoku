import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/logic/sudoku_generator.dart';
import 'package:sudoku/logic/sudoku_solver.dart';

void main() {
  group('Быстрый countSolutions', () {
    test('Даёт тот же результат, что медленный', () {
      final puzzle = SudokuGenerator().generate(Difficulty.medium).puzzle;
      expect(
        SudokuGenerator.countSolutionsFast(copyGrid(puzzle), limit: 3),
        SudokuGenerator.countSolutions(copyGrid(puzzle), limit: 3),
      );
    });

    test('Ускорение минимум в 5 раз', () {
      final puzzle = SudokuGenerator().generate(Difficulty.hard).puzzle;

      final sw1 = Stopwatch()..start();
      SudokuGenerator.countSolutions(copyGrid(puzzle), limit: 2);
      sw1.stop();

      final sw2 = Stopwatch()..start();
      SudokuGenerator.countSolutionsFast(copyGrid(puzzle), limit: 2);
      sw2.stop();

      print('Медленный: ${sw1.elapsedMilliseconds} мс, '
          'быстрый: ${sw2.elapsedMilliseconds} мс, '
          'ускорение: ${sw1.elapsedMilliseconds / sw2.elapsedMilliseconds.clamp(1, 999999)}x');

      expect(sw2.elapsedMilliseconds * 5, lessThan(sw1.elapsedMilliseconds));
    });
  });

  group('Оценка сложности', () {
    test('Лёгкая: только голые одиночки', () {
      for (var i = 0; i < 3; i++) {
        final puzzle = SudokuGenerator().generate(Difficulty.easy).puzzle;
        final score = rateDifficulty(puzzle);
        expect(score, 1, reason: 'попытка $i');
      }
    });

    test('Средняя: нужны скрытые одиночки', () {
      for (var i = 0; i < 3; i++) {
        final puzzle = SudokuGenerator().generate(Difficulty.medium).puzzle;
        final score = rateDifficulty(puzzle);
        expect(score, greaterThanOrEqualTo(2), reason: 'попытка $i');
      }
    });

    test('Сложная: пары или угадывание', () {
      for (var i = 0; i < 3; i++) {
        final puzzle = SudokuGenerator().generate(Difficulty.hard).puzzle;
        final score = rateDifficulty(puzzle);
        expect(score, greaterThanOrEqualTo(3), reason: 'попытка $i');
      }
    });
  });

  test('Генерация всех сложностей завершается за 10 секунд', () async {
    final sw = Stopwatch()..start();
    for (final d in Difficulty.values) {
      SudokuGenerator().generate(d);
    }
    sw.stop();
    print('Генерация 3 головоломок: ${sw.elapsedMilliseconds} мс');
    expect(sw.elapsedMilliseconds, lessThan(10000));
  }, timeout: const Timeout(Duration(seconds: 15)));
}
