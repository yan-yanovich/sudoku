import 'package:flutter/material.dart';

import '../models/game_mode.dart';
import 'app_storage.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(AppStorage storage)
      : _storage = storage,
        _themeMode = storage.themeMode,
        _gameMode = storage.gameMode;

  final AppStorage _storage;
  ThemeMode _themeMode;
  GameMode _gameMode;

  ThemeMode get themeMode => _themeMode;
  GameMode get gameMode => _gameMode;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    _storage.setThemeMode(mode);
    notifyListeners();
  }

  void setGameMode(GameMode mode) {
    if (mode == _gameMode) return;
    _gameMode = mode;
    _storage.setGameMode(mode);
    notifyListeners();
  }
}
