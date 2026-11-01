import 'package:flutter/material.dart';

import '../logic/sudoku_generator.dart';
import '../models/game_mode.dart';
import '../services/app_storage.dart';
import '../services/settings_controller.dart';
import '../utils/format.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'tutorial_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storage, required this.settings});

  final AppStorage storage;
  final SettingsController settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SavedGameInfo? _saved;

  @override
  void initState() {
    super.initState();
    _saved = widget.storage.savedGameInfo;
  }

  void _refresh() => setState(() => _saved = widget.storage.savedGameInfo);

  Future<void> _openGame(GameScreen screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _refresh();
  }

  Future<void> _continue() async {
    final json = widget.storage.loadGame();
    if (json == null) {
      _refresh();
      return;
    }
    await _openGame(GameScreen.resume(storage: widget.storage, savedGame: json));
  }

  Future<void> _startNew(Difficulty difficulty) async {
    if (_saved != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Начать новую игру?'),
          content: const Text('Незаконченная игра будет удалена.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Начать'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await widget.storage.abandonSavedGame();
    }
    if (!mounted) return;
    await _openGame(GameScreen.newGame(
      storage: widget.storage,
      difficulty: difficulty,
      mode: widget.settings.gameMode,
    ));
  }

  void _openStats() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StatsScreen(storage: widget.storage)),
      );

  void _openTutorial() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TutorialScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settings;
    final saved = _saved;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: ListenableBuilder(
                listenable: settings,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.grid_on, size: 80, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Судоку',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),

                    // Продолжить
                    if (saved != null) ...[
                      SizedBox(
                        height: 64,
                        child: FilledButton(
                          onPressed: _continue,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Продолжить',
                                  style: TextStyle(fontSize: 18)),
                              Text(
                                '${saved.difficulty.label} · ${saved.mode.label} · '
                                '${formatDuration(saved.elapsed)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Режим
                    const _SectionTitle('Режим'),
                    SegmentedButton<GameMode>(
                      segments: [
                        for (final m in GameMode.values)
                          ButtonSegment(
                            value: m,
                            label: Text(m.label),
                            icon: Icon(_modeIcon(m)),
                          ),
                      ],
                      selected: {settings.gameMode},
                      onSelectionChanged: (s) => settings.setGameMode(s.first),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      settings.gameMode.description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),

                    // Новая игра
                    const _SectionTitle('Новая игра'),
                    for (final d in Difficulty.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.tonal(
                            onPressed: () => _startNew(d),
                            child: Text(d.label, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),

                    // Обучение и статистика
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openTutorial,
                            icon: const Icon(Icons.school),
                            label: const Text('Обучение'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openStats,
                            icon: const Icon(Icons.bar_chart),
                            label: const Text('Статистика'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Тема
                    const _SectionTitle('Тема'),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Светлая'),
                            icon: Icon(Icons.light_mode)),
                        ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Тёмная'),
                            icon: Icon(Icons.dark_mode)),
                        ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('Авто'),
                            icon: Icon(Icons.brightness_auto)),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) => settings.setThemeMode(s.first),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _modeIcon(GameMode m) => switch (m) {
        GameMode.threeLives => Icons.favorite,
        GameMode.unlimited => Icons.all_inclusive,
      };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
