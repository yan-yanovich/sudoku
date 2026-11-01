import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/sudoku_generator.dart';
import '../models/game_mode.dart';
import '../models/game_stats.dart';
import 'puzzle_cache.dart';

/// Краткая информация о сохранённой игре для главного экрана.
class SavedGameInfo {
  const SavedGameInfo({
    required this.difficulty,
    required this.mode,
    required this.elapsed,
  });

  final Difficulty difficulty;
  final GameMode mode;
  final Duration elapsed;
}

class AppStorage {
  AppStorage._(this._prefs);

  final SharedPreferences _prefs;
    late final PuzzleCache puzzleCache;

  

    static Future<AppStorage> init() async {
    final storage = AppStorage._(await SharedPreferences.getInstance());
    storage.puzzleCache = await PuzzleCache.init();
    return storage;
  }


  static const _savedGameKey = 'saved_game';
  static const _themeKey = 'theme_mode';
  static const _gameModeKey = 'game_mode';
  static String _statsKey(Difficulty d) => 'stats_${d.name}';

  // ---------- Сохранённая игра ----------

  Future<void> saveGame(Map<String, dynamic> json) =>
      _prefs.setString(_savedGameKey, jsonEncode(json));

  Future<void> clearGame() => _prefs.remove(_savedGameKey);

  Map<String, dynamic>? loadGame() {
    final raw = _prefs.getString(_savedGameKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null; // повреждённые данные просто игнорируем
    }
  }

  SavedGameInfo? get savedGameInfo {
    final json = loadGame();
    if (json == null) return null;
    try {
      return SavedGameInfo(
        difficulty: Difficulty.values.byName(json['difficulty'] as String),
        mode: GameMode.values.byName(json['mode'] as String),
        elapsed: Duration(seconds: json['elapsed'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  /// Удаляет незаконченную игру и обнуляет серию побед.
  Future<void> abandonSavedGame() async {
    final info = savedGameInfo;
    if (info != null) await recordAbandoned(info.difficulty);
    await clearGame();
  }

  // ---------- Статистика ----------

  GameStats loadStats(Difficulty d) {
    final raw = _prefs.getString(_statsKey(d));
    if (raw == null) return GameStats();
    try {
      return GameStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return GameStats();
    }
  }

  Future<void> _updateStats(Difficulty d, void Function(GameStats) update) {
    final stats = loadStats(d);
    update(stats);
    return _prefs.setString(_statsKey(d), jsonEncode(stats.toJson()));
  }

  Future<void> recordStarted(Difficulty d) =>
      _updateStats(d, (s) => s.registerStart());

  Future<void> recordWin(Difficulty d, Duration time, {required bool perfect}) =>
      _updateStats(d, (s) => s.registerWin(time, perfect: perfect));

  Future<void> recordLost(Difficulty d) => _updateStats(d, (s) => s.resetStreak());

  Future<void> recordAbandoned(Difficulty d) =>
      _updateStats(d, (s) => s.resetStreak());

  Future<void> resetStats() async {
    for (final d in Difficulty.values) {
      await _prefs.remove(_statsKey(d));
    }
  }

  // ---------- Настройки ----------

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_prefs.getString(_themeKey)] ?? ThemeMode.system;

  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_themeKey, mode.name);

  GameMode get gameMode =>
      GameMode.values.asNameMap()[_prefs.getString(_gameModeKey)] ??
      GameMode.threeLives;

  Future<void> setGameMode(GameMode mode) =>
      _prefs.setString(_gameModeKey, mode.name);
}
