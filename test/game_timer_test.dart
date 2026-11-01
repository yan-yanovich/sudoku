import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku/game/game_controller.dart';
import 'package:sudoku/logic/sudoku_generator.dart';
import 'package:sudoku/services/app_storage.dart';

Map<String, dynamic> _savedGame() {
  final p = SudokuGenerator().generate(Difficulty.easy);
  return {
    'difficulty': Difficulty.easy.name,
    'mode': 'threeLives',
    'board': p.puzzle,
    'solution': p.solution,
    'fixed': [
      for (final row in p.puzzle) [for (final v in row) v != 0],
    ],
    'notes': [
      for (var r = 0; r < 9; r++) [for (var c = 0; c < 9; c++) <int>[]],
    ],
    'mistakes': 0,
    'hintsLeft': 3,
    'elapsed': 10,
  };
}

void main() {
  testWidgets('Тик таймера не перерисовывает весь экран', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.init();
    final controller = GameController.restore(storage, _savedGame());

    var screenUpdates = 0;
    var timerUpdates = 0;
    controller.addListener(() => screenUpdates++);
    controller.elapsedListenable.addListener(() => timerUpdates++);

    await tester.pump(const Duration(seconds: 3));

    expect(controller.elapsed, const Duration(seconds: 13));
    expect(timerUpdates, 3, reason: 'таймер должен тикать каждую секунду');
    expect(screenUpdates, 0, reason: 'экран не должен перестраиваться от таймера');

    controller.dispose();
  });

  testWidgets('Пауза останавливает время, продолжение — запускает', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.init();
    final controller = GameController.restore(storage, _savedGame());

    controller.pause();
    await tester.pump(const Duration(seconds: 5));
    expect(controller.elapsed, const Duration(seconds: 10));

    controller.resume();
    await tester.pump(const Duration(seconds: 2));
    expect(controller.elapsed, const Duration(seconds: 12));

    controller.dispose();
  });

  testWidgets('Время попадает в сохранение', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.init();
    final controller = GameController.restore(storage, _savedGame());

    await tester.pump(const Duration(seconds: 4));
    controller.save();

    expect(storage.savedGameInfo?.elapsed, const Duration(seconds: 14));
    controller.dispose();
  });
}
