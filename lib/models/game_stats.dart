import 'dart:math';

class GameStats {
  GameStats({
    this.started = 0,
    this.won = 0,
    this.perfectWins = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.bestTimeSeconds,
    this.totalWinTimeSeconds = 0,
  });

  int started;
  int won;
  int perfectWins; // победы без ошибок
  int currentStreak;
  int bestStreak;
  int? bestTimeSeconds;
  int totalWinTimeSeconds;

  double get winRate => started == 0 ? 0 : won / started;

  Duration? get bestTime =>
      bestTimeSeconds == null ? null : Duration(seconds: bestTimeSeconds!);

  Duration? get averageTime =>
      won == 0 ? null : Duration(seconds: totalWinTimeSeconds ~/ won);

  void registerStart() => started++;

  void registerWin(Duration time, {required bool perfect}) {
    won++;
    if (perfect) perfectWins++;
    currentStreak++;
    bestStreak = max(bestStreak, currentStreak);
    totalWinTimeSeconds += time.inSeconds;
    if (bestTimeSeconds == null || time.inSeconds < bestTimeSeconds!) {
      bestTimeSeconds = time.inSeconds;
    }
  }

  /// Поражение или брошенная игра обнуляют серию побед.
  void resetStreak() => currentStreak = 0;

  Map<String, dynamic> toJson() => {
        'started': started,
        'won': won,
        'perfectWins': perfectWins,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'bestTime': bestTimeSeconds,
        'totalWinTime': totalWinTimeSeconds,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        started: json['started'] as int? ?? 0,
        won: json['won'] as int? ?? 0,
        perfectWins: json['perfectWins'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        bestTimeSeconds: json['bestTime'] as int?,
        totalWinTimeSeconds: json['totalWinTime'] as int? ?? 0,
      );

  /// Суммарная статистика по всем уровням сложности.
  factory GameStats.combine(Iterable<GameStats> all) {
    final result = GameStats();
    for (final s in all) {
      result.started += s.started;
      result.won += s.won;
      result.perfectWins += s.perfectWins;
      result.totalWinTimeSeconds += s.totalWinTimeSeconds;
      result.currentStreak = max(result.currentStreak, s.currentStreak);
      result.bestStreak = max(result.bestStreak, s.bestStreak);
      if (s.bestTimeSeconds != null &&
          (result.bestTimeSeconds == null ||
              s.bestTimeSeconds! < result.bestTimeSeconds!)) {
        result.bestTimeSeconds = s.bestTimeSeconds;
      }
    }
    return result;
  }
}
