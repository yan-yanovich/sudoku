import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/sudoku_generator.dart';

/// Кэш предгенерированных головоломок.
class PuzzleCache {
  PuzzleCache._(this._prefs);

  final SharedPreferences _prefs;
  final Map<Difficulty, Completer<SudokuPuzzle>> _pending = {};

  static Future<PuzzleCache> init() async {
    final cache = PuzzleCache._(await SharedPreferences.getInstance());
    // Запустить фоновую генерацию для пустых слотов
    unawaited(cache._warmUp());
    return cache;
  }

  static String _key(Difficulty d) => 'puzzle_cache_${d.name}';

  /// Получить головоломку (из кэша или сгенерировать).
  Future<SudokuPuzzle> get(Difficulty difficulty) async {
    // Если уже генерируется — ждём
    if (_pending.containsKey(difficulty)) {
      return _pending[difficulty]!.future;
    }

    // Пробуем загрузить из кэша
    final cached = _load(difficulty);
    if (cached != null) {
      // Запустить генерацию следующей в фоне
      unawaited(_generateAndSave(difficulty));
      return cached;
    }

    // Кэша нет — генерируем сейчас
    return _generateAndSave(difficulty);
  }

  SudokuPuzzle? _load(Difficulty difficulty) {
    final raw = _prefs.getString(_key(difficulty));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SudokuPuzzle(
        puzzle: _parseGrid(json['puzzle']),
        solution: _parseGrid(json['solution']),
      );
    } catch (_) {
      return null;
    }
  }

  Future<SudokuPuzzle> _generateAndSave(Difficulty difficulty) async {
    final completer = Completer<SudokuPuzzle>();
    _pending[difficulty] = completer;

    try {
      final puzzle = await compute(generatePuzzle, difficulty);
      await _save(difficulty, puzzle);
      completer.complete(puzzle);
      return puzzle;
    } finally {
      _pending.remove(difficulty);
    }
  }

  Future<void> _save(Difficulty difficulty, SudokuPuzzle puzzle) =>
      _prefs.setString(
        _key(difficulty),
        jsonEncode({
          'puzzle': puzzle.puzzle,
          'solution': puzzle.solution,
        }),
      );

  Future<void> _warmUp() async {
    for (final d in Difficulty.values) {
      if (_load(d) == null) {
        unawaited(_generateAndSave(d));
      }
    }
  }

  List<List<int>> _parseGrid(dynamic raw) =>
      (raw as List).map((row) => (row as List).cast<int>().toList()).toList();
}
