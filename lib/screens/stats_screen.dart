import 'package:flutter/material.dart';

import '../logic/sudoku_generator.dart';
import '../models/game_stats.dart';
import '../services/app_storage.dart';
import '../utils/format.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.storage});
  final AppStorage storage;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сбросить статистику?'),
        content: const Text('Все данные будут удалены без возможности восстановления.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Сбросить')),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.storage.resetStats();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final perDifficulty = {
      for (final d in Difficulty.values) d: widget.storage.loadStats(d),
    };
    final total = GameStats.combine(perDifficulty.values);

    return DefaultTabController(
      length: Difficulty.values.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Статистика'),
          actions: [
            IconButton(
              tooltip: 'Сбросить',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmReset,
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Все'),
              for (final d in Difficulty.values) Tab(text: d.label),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StatsView(stats: total),
            for (final d in Difficulty.values) _StatsView(stats: perDifficulty[d]!),
          ],
        ),
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView({required this.stats});
  final GameStats stats;

  static String _time(Duration? d) => d == null ? '—' : formatDuration(d);

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.play_circle_outline, 'Начато игр', '${stats.started}'),
      (Icons.emoji_events_outlined, 'Побед', '${stats.won}'),
      (Icons.percent, 'Процент побед', '${(stats.winRate * 100).round()}%'),
      (Icons.verified_outlined, 'Без ошибок', '${stats.perfectWins}'),
      (Icons.timer_outlined, 'Лучшее время', _time(stats.bestTime)),
      (Icons.av_timer, 'Среднее время', _time(stats.averageTime)),
      (Icons.local_fire_department_outlined, 'Текущая серия', '${stats.currentStreak}'),
      (Icons.whatshot, 'Лучшая серия', '${stats.bestStreak}'),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            for (final (icon, label, value) in items)
              _StatCard(icon: icon, label: label, value: value),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
