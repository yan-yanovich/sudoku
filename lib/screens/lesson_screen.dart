import 'package:flutter/material.dart';

import '../tutorial/lesson_data.dart';
import '../tutorial/practice_controller.dart';
import '../tutorial/tutorial_board.dart';
import '../tutorial/tutorial_progress.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PracticeController _practice;
  late final Future<TutorialProgress> _progressFuture;

  /// Было ли задание выполнено при прошлом уведомлении контроллера.
  bool _wasCompleted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _practice = PracticeController(widget.lesson.practice);
    _wasCompleted = _practice.completed;
    _practice.addListener(_onPracticeChanged);
    _progressFuture = TutorialProgress.load();
    _markOpened();
  }

  @override
  void dispose() {
    _practice.removeListener(_onPracticeChanged);
    _practice.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markOpened() async {
    try {
      final progress = await _progressFuture;
      await progress.markOpened(widget.lesson.id);
    } catch (_) {
      // Прогресс не критичен для работы урока.
    }
  }

  /// Срабатывает только в момент перехода «не решено → решено».
  void _onPracticeChanged() {
    final completed = _practice.completed;
    if (completed && !_wasCompleted) _onCompleted();
    _wasCompleted = completed;
  }

  Future<void> _onCompleted() async {
    try {
      final progress = await _progressFuture;
      await progress.markCompleted(widget.lesson.id);
    } catch (_) {
      // Игнорируем ошибку сохранения.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Урок пройден! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _goToTab(int index) => _tabController.animateTo(index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Теория'),
            Tab(icon: Icon(Icons.visibility_outlined), text: 'Пример'),
            Tab(icon: Icon(Icons.edit_note), text: 'Практика'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _TheoryTab(lesson: widget.lesson, onNext: () => _goToTab(1)),
            _ExampleTab(lesson: widget.lesson, onNext: () => _goToTab(2)),
            _PracticeTab(
              controller: _practice,
              onBack: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Теория ─────────────────────────

class _TheoryTab extends StatelessWidget {
  const _TheoryTab({required this.lesson, required this.onNext});

  final Lesson lesson;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CenteredScroll(
      maxWidth: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${lesson.category.icon} ${lesson.category.title}',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 12),
          _RichTheory(text: lesson.theory),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('К примеру'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Текст теории с поддержкой разметки **жирный**.
class _RichTheory extends StatelessWidget {
  const _RichTheory({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge?.copyWith(height: 1.5);
    final bold = TextStyle(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    final parts = text.trim().split('**');

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          for (var i = 0; i < parts.length; i++)
            TextSpan(text: parts[i], style: i.isOdd ? bold : null),
        ],
      ),
    );
  }
}

// ───────────────────────── Пример ─────────────────────────

class _ExampleTab extends StatelessWidget {
  const _ExampleTab({required this.lesson, required this.onNext});

  final Lesson lesson;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CenteredScroll(
      maxWidth: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExampleBoard(example: lesson.example),
          const SizedBox(height: 12),
          MarkLegend(marks: lesson.example.marks),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                lesson.example.caption,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('К практике'),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Практика ─────────────────────────

class _PracticeTab extends StatelessWidget {
  const _PracticeTab({required this.controller, required this.onBack});

  final PracticeController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        return _CenteredScroll(
          maxWidth: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TaskCard(text: c.practice.task),
              const SizedBox(height: 8),
              _FeedbackBanner(feedback: c.feedback),
              const SizedBox(height: 12),
              PracticeBoard(controller: c),
              const SizedBox(height: 16),
              if (c.completed)
                _CompletedCard(onRetry: c.reset, onBack: onBack)
              else
                _PracticeControls(controller: c),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.assignment_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.feedback});

  final PracticeFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (feedback.kind) {
      FeedbackKind.info => (s.surfaceContainerHigh, s.onSurface, Icons.info_outline),
      FeedbackKind.success =>
        (s.primaryContainer, s.onPrimaryContainer, Icons.check_circle_outline),
      FeedbackKind.error =>
        (s.errorContainer, s.onErrorContainer, Icons.error_outline),
      FeedbackKind.hint =>
        (s.tertiaryContainer, s.onTertiaryContainer, Icons.lightbulb_outline),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey('${feedback.kind}:${feedback.text}'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(feedback.text, style: TextStyle(color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.onRetry, required this.onBack});

  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.emoji_events,
                size: 48, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(height: 8),
            Text(
              'Задание выполнено!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.replay),
                    label: const Text('Повторить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.list),
                    label: const Text('К урокам'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeControls extends StatelessWidget {
  const _PracticeControls({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      children: [
        Row(
          children: [
            _ActionButton(icon: Icons.refresh, label: 'Сброс', onTap: c.reset),
            _ActionButton(
                icon: Icons.backspace_outlined, label: 'Стереть', onTap: c.erase),
            _ActionButton(
              icon: Icons.edit_outlined,
              label: c.notesMode ? 'Заметки: вкл' : 'Заметки',
              active: c.notesMode,
              onTap: c.toggleNotesMode,
            ),
            _ActionButton(
                icon: Icons.auto_fix_high,
                label: 'Кандидаты',
                onTap: c.fillCandidates),
            _ActionButton(
                icon: Icons.lightbulb_outline, label: 'Подсказка', onTap: c.hint),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(9, (i) {
            final n = i + 1;
            final remaining = 9 - c.digitCount(n);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _NumberButton(
                  number: n,
                  remaining: remaining,
                  notesMode: c.notesMode,
                  onTap: remaining > 0 ? () => c.enterNumber(n) : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = onTap == null ? colors.outline : colors.primary;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: active ? colors.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(color: color, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    required this.number,
    required this.remaining,
    required this.notesMode,
    this.onTap,
  });

  final int number;
  final int remaining;
  final bool notesMode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    final background = !enabled
        ? colors.surfaceContainerHighest
        : notesMode
            ? colors.secondaryContainer
            : colors.primaryContainer;
    final foreground = !enabled
        ? colors.outline
        : notesMode
            ? colors.onSecondaryContainer
            : colors.onPrimaryContainer;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                '$number',
                style: TextStyle(
                  fontSize: notesMode ? 18 : 24,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              Text(
                enabled ? '$remaining' : '✓',
                style: TextStyle(fontSize: 11, color: colors.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Общее ─────────────────────────

/// Прокручиваемый контент, ограниченный по ширине и выровненный по центру.
class _CenteredScroll extends StatelessWidget {
  const _CenteredScroll({required this.child, required this.maxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
