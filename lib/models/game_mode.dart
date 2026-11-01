enum GameMode { threeLives, unlimited }

extension GameModeX on GameMode {
  String get label => switch (this) {
        GameMode.threeLives => '3 жизни',
        GameMode.unlimited => 'Без лимита',
      };

  String get description => switch (this) {
        GameMode.threeLives => 'После 3 ошибок игра заканчивается',
        GameMode.unlimited => 'Ошибаться можно сколько угодно',
      };
}
