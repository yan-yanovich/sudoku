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
  late final PracticeController _practiceController;
  late final Future<TutorialProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _practiceController = PracticeController(widget.lesson.practice);
    _progressFuture = TutorialProgress.load();
    _markOpened();
  }

  Future<void> _markOpened() async {
    final progress = await _progressFuture;
    await progress.markOpened(widget.lesson.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _practiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Теория'),
            Tab(text: 'Пример'),
            Tab(text: 'Практика'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TheoryTab(lesson: widget.lesson),
          _ExampleTab(lesson: widget.lesson),
          _PracticeTab(
            controller: _practiceController,
            progressFuture: _progressFuture,
            lessonId: widget.lesson.id,
          ),
        ],
      ),
    );
  }
}

class _TheoryTab extends StatelessWidget {
  const _TheoryTab({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.theory, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _ExampleTab extends StatelessWidget {
  const _ExampleTab({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              ExampleBoard(example: lesson.example),
              const SizedBox(height: 16),
              Text(lesson.example.caption,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final color in MarkColor.values)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: markBackground(colors, color),
                            border: Border.all(color: colors.outline),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(color.legend,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeTab extends StatelessWidget {
  const _PracticeTab({
    required this.controller,
    required this.progressFuture,
    required this.lessonId,
  });

  final PracticeController controller;
  final Future<TutorialProgress> progressFuture;
  final String lessonId;

  Future<void> _onCompleted(BuildContext context) async {
    final progress = await progressFuture;
    await progress.markCompleted(lessonId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.completed) {
          _onCompleted(context);
        }
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  _FeedbackBanner(feedback: controller.feedback),
                  const SizedBox(height: 12),
                  PracticeBoard(controller: controller),
                  const SizedBox(height: 16),
                  _PracticeControls(controller: controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.feedback});

  final PracticeFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (bgColor, iconData) = switch (feedback.kind) {
      FeedbackKind.info => (colors.surfaceContainerHigh, Icons.info_outline),
      FeedbackKind.success => (colors.primaryContainer, Icons.check_circle_outline),
      FeedbackKind.error => (colors.errorContainer, Icons.error_outline),
      FeedbackKind.hint => (Colors.amber.shade100, Icons.lightbulb_outline),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(iconData, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(feedback.text)),
        ],
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
                icon: Icons.refresh, label: 'Сброс', onTap: c.reset),
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
                icon: Icons.lightbulb_outline,
                label: 'Подсказка',
                onTap: c.hint),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(9, (i) {
            final n = i + 1;
            final count = 9 - c.digitCount(n);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _NumberButton(
                  number: n,
                  remaining: count,
                  notesMode: c.notesMode,
                  onTap: count > 0 ? () => c.enterNumber(n) : null,
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

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
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
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
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
