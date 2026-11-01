import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logic/sudoku_generator.dart';
import '../models/game_mode.dart';
import '../services/app_storage.dart';

enum GameStatus { loading, playing, won, lost }

class _CellSnapshot {
  _CellSnapshot(this.row, this.col, this.value, Set<int> notes)
      : notes = Set.of(notes);

  final int row;
  final int col;
  final int value;
  final Set<int> notes;
}

class GameController extends ChangeNotifier {
  GameController({
    required this.storage,
    required this.difficulty,
    required this.mode,
  });

  factory GameController.restore(AppStorage storage, Map<String, dynamic> json) {
    final controller = GameController(
      storage: storage,
      difficulty: Difficulty.values.byName(json['difficulty'] as String),
      mode: GameMode.values.byName(json['mode'] as String),
    );
    controller._loadFromJson(json);
    return controller;
  }

  static const int maxMistakes = 3;
  static const int maxHints = 3;

  final AppStorage storage;
  final Difficulty difficulty;
  final GameMode mode;

  GameStatus status = GameStatus.loading;
  List<List<int>> board = [];
  List<List<int>> solution = [];
  List<List<bool>> fixed = [];
  List<List<Set<int>>> notes = [];

  int? selectedRow;
  int? selectedCol;
  bool notesMode = false;
  bool isPaused = false;
  int mistakes = 0;
  int hintsLeft = maxHints;

  // ★ Время хранится в отдельном ValueNotifier.
  //   Его изменение НЕ вызывает перерисовку всего экрана.
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);

  /// ★ Подписка только на время — для виджета таймера.
  ValueListenable<Duration> get elapsedListenable => _elapsed;

  /// ★ Обычное свойство, как раньше: используется в сохранении,
  ///   статистике и диалоге победы.
  Duration get elapsed => _elapsed.value;
  set elapsed(Duration value) => _elapsed.value = value;

  final List<List<_CellSnapshot>> _history = [];
  Timer? _timer;
  int _generationId = 0;
  bool _disposed = false;

  bool get isLoading => status == GameStatus.loading;
  bool get isPlaying => status == GameStatus.playing;
  bool get hasLimitedLives => mode == GameMode.threeLives;
  int get livesLeft => maxMistakes - mistakes;

  int get selectedValue =>
      selectedRow == null ? 0 : board[selectedRow!][selectedCol!];

  bool isWrong(int r, int c) => board[r][c] != 0 && board[r][c] != solution[r][c];

  bool isRelated(int r, int c) {
    if (selectedRow == null) return false;
    final sr = selectedRow!;
    final sc = selectedCol!;
    return r == sr || c == sc || (r ~/ 3 == sr ~/ 3 && c ~/ 3 == sc ~/ 3);
  }

  int remainingCount(int number) {
    var placed = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == number && solution[r][c] == number) placed++;
      }
    }
    return 9 - placed;
  }

  bool get _canEdit =>
      isPlaying &&
      !isPaused &&
      selectedRow != null &&
      !fixed[selectedRow!][selectedCol!];

   Future<void> startNewGame() async {
    if (isPlaying) storage.recordAbandoned(difficulty);
    storage.clearGame();
    _timer?.cancel();
    status = GameStatus.loading;
    isPaused = false;
    notifyListeners();

    final requestId = ++_generationId;
    final puzzle = await storage.puzzleCache.get(difficulty); // ← изменение
    if (_disposed || requestId != _generationId) return;

    board = copyGrid(puzzle.puzzle);
    solution = puzzle.solution;
    fixed = List.generate(9, (r) => List.generate(9, (c) => board[r][c] != 0));
    notes = _emptyNotes();
    selectedRow = null;
    selectedCol = null;
    notesMode = false;
    mistakes = 0;
    hintsLeft = maxHints;
    elapsed = Duration.zero;
    _history.clear();
    status = GameStatus.playing;

    storage.recordStarted(difficulty);
    _startTimer();
    save();
    notifyListeners();
  }

  }

  void pause() {
    if (!isPlaying || isPaused) return;
    isPaused = true;
    _timer?.cancel();
    save();
    notifyListeners();
  }

  void resume() {
    if (!isPlaying || !isPaused) return;
    isPaused = false;
    _startTimer();
    notifyListeners();
  }

  void save() {
    if (isPlaying) storage.saveGame(toJson());
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // ★ Обновляется только _elapsed → перерисуется только текст таймера.
      //   notifyListeners() здесь больше НЕ вызывается.
      elapsed += const Duration(seconds: 1);
    });
  }

  void _finish(GameStatus result) {
    status = result;
    isPaused = false;
    _timer?.cancel();
    storage.clearGame();
    if (result == GameStatus.won) {
      storage.recordWin(difficulty, elapsed, perfect: mistakes == 0);
    } else {
      storage.recordLost(difficulty);
    }
  }

  void _checkWin() {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] != solution[r][c]) return;
      }
    }
    _finish(GameStatus.won);
  }

  void selectCell(int r, int c) {
    if (!isPlaying || isPaused) return;
    selectedRow = r;
    selectedCol = c;
    notifyListeners();
  }

  void toggleNotesMode() {
    if (!isPlaying || isPaused) return;
    notesMode = !notesMode;
    notifyListeners();
  }

  void enterNumber(int number) {
    if (!_canEdit) return;
    final r = selectedRow!;
    final c = selectedCol!;

    if (notesMode) {
      _toggleNote(r, c, number);
      return;
    }
    if (board[r][c] == number) return;

    final changes = [_snapshot(r, c)];
    board[r][c] = number;
    notes[r][c].clear();

    final correct = number == solution[r][c];
    if (correct) {
      for (final (pr, pc) in _peers(r, c)) {
        if (notes[pr][pc].contains(number)) {
          changes.add(_snapshot(pr, pc));
          notes[pr][pc].remove(number);
        }
      }
    }
    _history.add(changes);

    if (correct) {
      _checkWin();
    } else {
      mistakes++;
      if (hasLimitedLives && mistakes >= maxMistakes) _finish(GameStatus.lost);
    }
    save();
    notifyListeners();
  }

  void _toggleNote(int r, int c, int number) {
    if (board[r][c] != 0) return;
    _history.add([_snapshot(r, c)]);
    if (!notes[r][c].remove(number)) notes[r][c].add(number);
    save();
    notifyListeners();
  }

  void erase() {
    if (!_canEdit) return;
    final r = selectedRow!;
    final c = selectedCol!;
    if (board[r][c] == 0 && notes[r][c].isEmpty) return;

    _history.add([_snapshot(r, c)]);
    board[r][c] = 0;
    notes[r][c].clear();
    save();
    notifyListeners();
  }

  void undo() {
    if (!isPlaying || isPaused || _history.isEmpty) return;
    final changes = _history.removeLast();
    for (final s in changes) {
      if (fixed[s.row][s.col]) continue;
      board[s.row][s.col] = s.value;
      notes[s.row][s.col] = Set.of(s.notes);
    }
    selectedRow = changes.first.row;
    selectedCol = changes.first.col;
    save();
    notifyListeners();
  }

  void hint() {
    if (!_canEdit || hintsLeft == 0) return;
    final r = selectedRow!;
    final c = selectedCol!;
    if (board[r][c] == solution[r][c]) return;

    final n = solution[r][c];
    board[r][c] = n;
    notes[r][c].clear();
    fixed[r][c] = true;
    for (final (pr, pc) in _peers(r, c)) {
      notes[pr][pc].remove(n);
    }
    hintsLeft--;
    _checkWin();
    save();
    notifyListeners();
  }

  _CellSnapshot _snapshot(int r, int c) =>
      _CellSnapshot(r, c, board[r][c], notes[r][c]);

  static List<List<Set<int>>> _emptyNotes() =>
      List.generate(9, (_) => List.generate(9, (_) => <int>{}));

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

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty.name,
        'mode': mode.name,
        'board': board,
        'solution': solution,
        'fixed': fixed,
        'notes': notes
            .map((row) => row.map((cell) => cell.toList()..sort()).toList())
            .toList(),
        'mistakes': mistakes,
        'hintsLeft': hintsLeft,
        'elapsed': elapsed.inSeconds,
      };

  void _loadFromJson(Map<String, dynamic> json) {
    List<List<int>> parseGrid(dynamic raw) =>
        (raw as List).map((row) => (row as List).cast<int>().toList()).toList();

    board = parseGrid(json['board']);
    solution = parseGrid(json['solution']);
    fixed = (json['fixed'] as List)
        .map((row) => (row as List).cast<bool>().toList())
        .toList();
    notes = (json['notes'] as List)
        .map((row) => (row as List)
            .map((cell) => (cell as List).cast<int>().toSet())
            .toList())
        .toList();
    mistakes = json['mistakes'] as int;
    hintsLeft = json['hintsLeft'] as int;
    elapsed = Duration(seconds: json['elapsed'] as int);
    status = GameStatus.playing;
    _startTimer();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _elapsed.dispose(); // ★ освобождаем ValueNotifier
    super.dispose();
  }
}
