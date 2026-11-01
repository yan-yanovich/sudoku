import 'package:flutter/foundation.dart';

import '../logic/sudoku_generator.dart';
import 'lesson_data.dart';

enum FeedbackKind { info, success, error, hint }

class PracticeFeedback {
  const PracticeFeedback(this.text, {this.kind = FeedbackKind.info});

  final String text;
  final FeedbackKind kind;
}

enum _Unit { row, col, box }

extension on _Unit {
  String get here => switch (this) {
        _Unit.row => 'в этой строке',
        _Unit.col => 'в этом столбце',
        _Unit.box => 'в этом квадрате',
      };

  String get highlighted => switch (this) {
        _Unit.row => 'в выделенной строке',
        _Unit.col => 'в выделенном столбце',
        _Unit.box => 'в выделенном квадрате',
      };
}

/// Логика практического задания урока.
class PracticeController extends ChangeNotifier {
  PracticeController(this.practice) {
    reset();
  }

  final LessonPractice practice;

  late List<List<int>> board;
  late List<List<int>> solution;
  late List<List<bool>> given; // изначальные цифры
  late List<List<bool>> locked; // изначальные и правильно поставленные
  late List<List<Set<int>>> notes;
  late PracticeFeedback feedback;

  int? selectedRow;
  int? selectedCol;
  bool notesMode = false;
  bool completed = false;
  int mistakes = 0;

  (int, int)? hintCell;
  Set<(int, int)> hintArea = {};

  static final List<(_Unit, List<(int, int)>)> _units = [
    for (var r = 0; r < 9; r++)
      (_Unit.row, [for (var c = 0; c < 9; c++) (r, c)]),
    for (var c = 0; c < 9; c++)
      (_Unit.col, [for (var r = 0; r < 9; r++) (r, c)]),
    for (var b = 0; b < 9; b++)
      (
        _Unit.box,
        [for (var i = 0; i < 9; i++) (b ~/ 3 * 3 + i ~/ 3, b % 3 * 3 + i % 3)]
      ),
  ];

  // ---------- Состояние ----------

  void reset() {
    board = practice.puzzle;
    solution = practice.solution;
    given = [
      for (final row in board) [for (final v in row) v != 0],
    ];
    locked = [for (final row in given) List<bool>.from(row)];
    notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
    if (practice.startWithCandidates) _fillCandidates();
    selectedRow = null;
    selectedCol = null;
    notesMode = false;
    completed = false;
    mistakes = 0;
    feedback = PracticeFeedback(practice.task);
    _clearHint();
    notifyListeners();
  }

  int get selectedValue =>
      selectedRow == null ? 0 : board[selectedRow!][selectedCol!];

  bool isRelated(int r, int c) {
    if (selectedRow == null) return false;
    final sr = selectedRow!;
    final sc = selectedCol!;
    return r == sr || c == sc || (r ~/ 3 == sr ~/ 3 && c ~/ 3 == sc ~/ 3);
  }

  int digitCount(int n) {
    var count = 0;
    for (final row in board) {
      for (final v in row) {
        if (v == n) count++;
      }
    }
    return count;
  }

  /// Цифры, которые можно поставить в клетку по правилам.
  Set<int> candidatesOf(int r, int c) {
    if (board[r][c] != 0) return {};
    return {
      for (var n = 1; n <= 9; n++)
        if (SudokuGenerator.isValidPlacement(board, r, c, n)) n,
    };
  }

  // ---------- Действия ----------

  void selectCell(int r, int c) {
    if (completed) return;
    selectedRow = r;
    selectedCol = c;
    notifyListeners();
  }

  void toggleNotesMode() {
    if (completed) return;
    notesMode = !notesMode;
    notifyListeners();
  }

  void fillCandidates() {
    if (completed) return;
    _fillCandidates();
    feedback = const PracticeFeedback(
        'Кандидаты расставлены во всех пустых клетках.');
    notifyListeners();
  }

  void enterNumber(int n) {
    final r = selectedRow;
    final c = selectedCol;
    if (completed || r == null || c == null) return;

    if (locked[r][c]) {
      feedback = const PracticeFeedback(
          'Эта клетка уже заполнена. Выберите пустую клетку.');
      notifyListeners();
      return;
    }

    if (notesMode) {
      if (!notes[r][c].remove(n)) notes[r][c].add(n);
      notifyListeners();
      return;
    }

    if (n != solution[r][c]) {
      mistakes++;
      feedback = PracticeFeedback(_whyWrong(r, c, n), kind: FeedbackKind.error);
      notifyListeners();
      return;
    }

    final reason = _whyRight(r, c, n);
    _place(r, c, n);
    if (!completed) {
      feedback = PracticeFeedback(reason, kind: FeedbackKind.success);
    }
    notifyListeners();
  }

  void erase() {
    final r = selectedRow;
    final c = selectedCol;
    if (completed || r == null || c == null || locked[r][c]) return;
    notes[r][c].clear();
    notifyListeners();
  }

  /// Ищет следующий логичный ход и подсвечивает его.
  void hint() {
    if (completed) return;

    // 1. Голая одиночка
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] != 0) continue;
        if (candidatesOf(r, c).length == 1) {
          final area = {for (final u in _unitsOf(r, c)) ...u.$2};
          _showHint(r, c, area,
              'Голая одиночка: в выделенную клетку подходит только одна цифра. Проверьте её строку, столбец и квадрат.');
          return;
        }
      }
    }

    // 2. Скрытая одиночка
    for (final (kind, cells) in _units) {
      for (var n = 1; n <= 9; n++) {
        if (cells.any((p) => board[p.$1][p.$2] == n)) continue;
        final places = cells
            .where((p) =>
                board[p.$1][p.$2] == 0 &&
                SudokuGenerator.isValidPlacement(board, p.$1, p.$2, n))
            .toList();
        if (places.length == 1) {
          final (r, c) = places.first;
          _showHint(r, c, cells.toSet(),
              'Скрытая одиночка: ${kind.highlighted} цифра $n может стоять только в одной клетке.');
          return;
        }
      }
    }

    // 3. Простых ходов нет — открываем клетку
    (int, int)? target;
    final sr = selectedRow;
    final sc = selectedCol;
    if (sr != null && sc != null && board[sr][sc] == 0) target = (sr, sc);
    target ??= _firstEmpty();
    if (target == null) return;
    final (r, c) = target;
    selectedRow = r;
    selectedCol = c;
    _place(r, c, solution[r][c]);
    if (!completed) {
      feedback = const PracticeFeedback(
          'Простых ходов не нашлось — я открыл одну клетку.',
          kind: FeedbackKind.hint);
    }
    notifyListeners();
  }

  // ---------- Вспомогательное ----------

  void _fillCandidates() {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        notes[r][c] = candidatesOf(r, c);
      }
    }
  }

  void _place(int r, int c, int n) {
    board[r][c] = n;
    locked[r][c] = true;
    notes[r][c].clear();
    for (final (pr, pc) in _peers(r, c)) {
      notes[pr][pc].remove(n);
    }
    _clearHint();
    if (_isSolved()) {
      completed = true;
      feedback = const PracticeFeedback(
          'Задание выполнено! Урок отмечен как пройденный. 🎉',
          kind: FeedbackKind.success);
    }
  }

  String _whyWrong(int r, int c, int n) {
    if (board[r].contains(n)) return 'Цифра $n уже есть в этой строке.';
    for (var i = 0; i < 9; i++) {
      if (board[i][c] == n) return 'Цифра $n уже есть в этом столбце.';
    }
    final br = r ~/ 3 * 3;
    final bc = c ~/ 3 * 3;
    for (var i = br; i < br + 3; i++) {
      for (var j = bc; j < bc + 3; j++) {
        if (board[i][j] == n) return 'Цифра $n уже есть в этом квадрате.';
      }
    }
    return 'Правил цифра $n пока не нарушает, но в решении здесь другая цифра. Ищите ход, в котором вы уверены.';
  }

  String _whyRight(int r, int c, int n) {
    if (candidatesOf(r, c).length == 1) {
      return 'Верно! Голая одиночка: остальные цифры уже есть в строке, столбце или квадрате.';
    }
    for (final (kind, cells) in _unitsOf(r, c)) {
      final places = cells.where((p) =>
          board[p.$1][p.$2] == 0 &&
          SudokuGenerator.isValidPlacement(board, p.$1, p.$2, n));
      if (places.length == 1) {
        return 'Верно! Скрытая одиночка: ${kind.here} цифре $n больше некуда встать.';
      }
    }
    return 'Верно! Этот ход требует более сложной логики — попробуйте понять, почему здесь $n.';
  }

  void _showHint(int r, int c, Set<(int, int)> area, String text) {
    final repeated = hintCell == (r, c);
    hintCell = (r, c);
    hintArea = area;
    selectedRow = r;
    selectedCol = c;
    feedback = PracticeFeedback(
      repeated
          ? '$text Ответ: ${solution[r][c]}.'
          : '$text Нажмите «Подсказка» ещё раз, чтобы увидеть ответ.',
      kind: FeedbackKind.hint,
    );
    notifyListeners();
  }

  void _clearHint() {
    hintCell = null;
    hintArea = {};
  }

  Iterable<(_Unit, List<(int, int)>)> _unitsOf(int r, int c) =>
      _units.where((u) => u.$2.contains((r, c)));

  (int, int)? _firstEmpty() {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == 0) return (r, c);
      }
    }
    return null;
  }

  bool _isSolved() {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] != solution[r][c]) return false;
      }
    }
    return true;
  }

  static Iterable<(int, int)> _peers(int r, int c) sync* {
    for (var i = 0; i < 9; i++) {
      if (i != c) yield (r, i);
      if (i != r) yield (i, c);
    }
    final br = r ~/ 3 * 3;
    final bc = c ~/ 3 * 3;
    for (var rr = br; rr < br + 3; rr++) {
      for (var cc = bc; cc < bc + 3; cc++) {
        if (rr != r && cc != c) yield (rr, cc);
      }
    }
  }
}
