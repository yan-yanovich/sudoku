import 'package:flutter/material.dart';

import '../tutorial/lesson_data.dart';
import '../tutorial/tutorial_progress.dart';
import 'lesson_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late final Future<TutorialProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = TutorialProgress.load();
  }

  void _openLesson(Lesson lesson) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обучение')),
      body: FutureBuilder<TutorialProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final progress = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final category in LessonCategory.values)
                _CategorySection(
                  category: category,
                  progress: progress,
                  onTap: _openLesson,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.progress,
    required this.onTap,
  });

  final LessonCategory category;
  final TutorialProgress progress;
  final void Function(Lesson) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessons = allLessons.where((l) => l.category == category).toList();
    final completed = lessons.where((l) => progress.completed.contains(l.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.title, style: theme.textTheme.titleLarge),
                    Text(
                      category.subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                '$completed/${lessons.length}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
        for (final lesson in lessons)
          _LessonCard(
            lesson: lesson,
            isCompleted: progress.completed.contains(lesson.id),
            isOpened: progress.opened.contains(lesson.id),
            onTap: () => onTap(lesson),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.isCompleted,
    required this.isOpened,
    required this.onTap,
  });

  final Lesson lesson;
  final bool isCompleted;
  final bool isOpened;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          child: Icon(
            isCompleted ? Icons.check : Icons.circle_outlined,
            color: isCompleted ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
        title: Text(lesson.title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
