import 'package:shared_preferences/shared_preferences.dart';

/// Прогресс обучения: какие уроки открыты и пройдены.
class TutorialProgress {
  TutorialProgress._(this._prefs);

  final SharedPreferences _prefs;

  static Future<TutorialProgress> load() async =>
      TutorialProgress._(await SharedPreferences.getInstance());

  static const _completedKey = 'tutorial_completed';
  static const _openedKey = 'tutorial_opened';

  Set<String> get completed =>
      (_prefs.getStringList(_completedKey) ?? const []).toSet();

  Set<String> get opened =>
      (_prefs.getStringList(_openedKey) ?? const []).toSet();

  Future<void> markOpened(String id) =>
      _prefs.setStringList(_openedKey, (opened..add(id)).toList());

  Future<void> markCompleted(String id) =>
      _prefs.setStringList(_completedKey, (completed..add(id)).toList());

  Future<void> reset() async {
    await _prefs.remove(_completedKey);
    await _prefs.remove(_openedKey);
  }
}
