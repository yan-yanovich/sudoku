import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../logic/sudoku_generator.dart';
import '../models/game_mode.dart';
import '../services/app_storage.dart';
import '../utils/format.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen.newGame({
    super.key,
    required this.storage,
    required Difficulty this.difficulty,
    required GameMode this.mode,
  }) : savedGame = null;

  const GameScreen.resume({
    super.key,
    required this.storage,
    required Map<String, dynamic> this.savedGame,
  })  : difficulty = null,
        mode = null;

  final AppStorage storage;
  final Difficulty? difficulty;
  final GameMode? mode;
  final Map<String, dynamic>? savedGame;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameController _controller;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.savedGame;
    _controller = saved != null
        ? GameController.restore(widget.storage, saved)
        : (GameController(
            storage: widget.storage,
            difficulty: widget.difficulty!,
            mode: widget.mode!,
          )..startNewGame());
    _controller.addListener(_onGameChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  /// Приложение свернули или закрывают: ставим паузу (пауза сохраняет игру).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onGameChanged);
    _controller.save();
    _controller.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    final status = _controller.status;
    if (status == GameStatus.playing || status == GameStatus.loading) {
      _dialogShown = false;
      return;
    }
    if (_dialogShown) return;
    _dialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showEndDialog());
  }

  Future<void> _confirmNewGame() async {
    if (_controller.isPlaying) {
      final wasPaused = _controller.isPaused;
      _controller.pause(); // таймер стоит, пока открыт диалог
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Новая игра?'),
          content: const Text('Текущий прогресс будет потерян.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Начать')),
          ],
        ),
      );
      if (confirmed != true) {
        if (!wasPaused) _controller.resume();
        return;
      }
    }
    _controller.startNewGame();
  }

  Future<void> _showEndDialog() async {
    if (!mounted) return;
    final c = _controller;
    final won = c.status == GameStatus.won;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(won ? 'Победа! 🎉' : 'Игра окончена'),
        content: Text(won
            ? 'Время: ${formatDuration(c.elapsed)}\nОшибок: ${c.mistakes}'
            : 'Вы потеряли все ${GameController.maxMistakes} жизни.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('В меню'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              c.startNewGame();
            },
            child: const Text('Новая игра'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Сохраняем до возврата в меню, чтобы там сразу было актуальное время
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _controller.save();
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          final theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.difficulty.label),
                  Text(c.mode.label, style: theme.textTheme.bodySmall),
                ],
              ),
              actions: [
                if (c.isPlaying)
                  IconButton(
                    tooltip: c.isPaused ? 'Продолжить' : 'Пауза',
                    icon: Icon(c.isPaused ? Icons.play_arrow : Icons.pause),
                    onPressed: c.isPaused ? c.resume : c.pause,
                  ),
                IconButton(
                  tooltip: 'Новая игра',
                  icon: const Icon(Icons.refresh),
                  onPressed: c.isLoading ? null : _confirmNewGame,
                ),
              ],
            ),
            body: SafeArea(
              child: c.isLoading ? const _LoadingView() : _buildGame(c),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGame(GameController c) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoBar(controller: c),
              const SizedBox(height: 12),
              Stack(
                children: [
                  SudokuBoard(controller: c),
                  if (c.isPaused)
                    Positioned.fill(child: _PauseOverlay(onResume: c.resume)),
                ],
              ),
              const SizedBox(height: 24),
              NumberPad(controller: c),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Генерируем судоку…'),
          ],
        ),
      );
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume});
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface, // скрываем поле, чтобы не подглядывать
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_circle_outline, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text('Пауза', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Продолжить'),
          ),
        ],
      ),
    );
  }
}

class _InfoBar extends StatelessWidget {
  const _InfoBar({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final style = Theme.of(context).textTheme.titleMedium;

    final Widget lives = c.hasLimitedLives
        ? Row(
            children: List.generate(
              GameController.maxMistakes,
              (i) => Icon(
                i < c.livesLeft ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
                size: 22,
              ),
            ),
          )
        : Text('Ошибки: ${c.mistakes}', style: style);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        lives,
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 20),
            const SizedBox(width: 4),
            _TimerText(listenable: c.elapsedListenable, style: style),
          ],
        ),
      ],
    );
  }
}

/// Текст таймера. Каждую секунду перестраивается ТОЛЬКО этот виджет.
class _TimerText extends StatelessWidget {
  const _TimerText({required this.listenable, this.style});

  final ValueListenable<Duration> listenable;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<Duration>(
        valueListenable: listenable,
        builder: (context, elapsed, _) => Text(
          formatDuration(elapsed),
          // Цифры одинаковой ширины — текст не «дрожит» при смене секунд
          style: style?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
