import 'package:flutter/material.dart';

import 'lesson_data.dart';
import 'practice_controller.dart';

Color markBackground(ColorScheme colors, MarkColor? color) => switch (color) {
      null => colors.surface,
      MarkColor.focus => colors.primaryContainer,
      MarkColor.related => colors.secondaryContainer,
      MarkColor.pattern => Colors.amber.withValues(alpha: 0.45),
      MarkColor.remove => colors.errorContainer,
      MarkColor.success => Colors.green.withValues(alpha: 0.35),
    };

/// Сетка 9×9 с толстыми линиями между квадратами.
class BoardFrame extends StatelessWidget {
  const BoardFrame({super.key, required this.cellBuilder, this.onTap});

  final Widget Function(BuildContext context, int row, int col) cellBuilder;
  final void Function(int row, int col)? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final thick = BorderSide(width: 2, color: colors.onSurface);
    final thin = BorderSide(width: 0.5, color: colors.outlineVariant);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(width: 2
                                             import 'package:flutter/material.dart';

import 'lesson_data.dart';
import 'practice_controller.dart';

Color markBackground(ColorScheme colors, MarkColor? color) => switch (color) {
      null => colors.surface,
      MarkColor.focus => colors.primaryContainer,
      MarkColor.related => colors.secondaryContainer,
      MarkColor.pattern => Colors.amber.withValues(alpha: 0.45),
      MarkColor.remove => colors.errorContainer,
      MarkColor.success => Colors.green.withValues(alpha: 0.35),
    };

/// Сетка 9×9 с толстыми линиями между квадратами.
class BoardFrame extends StatelessWidget {
  const BoardFrame({super.key, required this.cellBuilder, this.onTap});

  final Widget Function(BuildContext context, int row, int col) cellBuilder;
  final void Function(int row, int col)? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final thick = BorderSide(width: 2, color: colors.onSurface);
    final thin = BorderSide(width: 0.5, color: colors.outlineVariant);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(width: 2, color: colors.onSurface)),
        child: Column(
          children: List.generate(
            9,
            (r) => Expanded(
              child: Row(
                children: List.generate(
                  9,
                  (c) => Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTap == null ? null : () => onTap!(r, c),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: c == 8
                                ? BorderSide.none
                                : (c == 2 || c == 5 ? thick : thin),
                            bottom: r == 8
                                ? BorderSide.none
                                : (r == 2 || r == 5 ? thick : thin),
                          ),
                        ),
                        child: cellBuilder(context, r, c),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Доска примера: неинтерактивная, с подсветкой и надписями.
class ExampleBoard extends StatelessWidget {
  const ExampleBoard({super.key, required this.example});

  final LessonExample example;

  @override
  Widget build(BuildContext context) {
    final board = example.board;
    final markMap = <(int, int), Mark>{
      for (final m in example.marks) (m.row, m.col): m,
    };

    return BoardFrame(
      cellBuilder: (context, r, c) {
        final mark = markMap[(r, c)];
        final colors = Theme.of(context).colorScheme;
        return Container(
          color: markBackground(colors, mark?.color),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(2),
          child: mark?.notes case final notes? => _NotesWidget(notes: notes)
              when notes.isNotEmpty
            else => _CellText(
                value: board[r][c],
                label: mark?.text,
                color: board[r][c] == 0 ? colors.primary : colors.onSurface,
              ),
        );
      },
    );
  }
}

/// Доска практики: интерактивная, с заметками и подсказками.
class PracticeBoard extends StatelessWidget {
  const PracticeBoard({super.key, required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return BoardFrame(
      onTap: controller.selectCell,
      cellBuilder: (context, r, c) => _PracticeCell(controller: controller, r: r, c: c),
    );
  }
}

class _PracticeCell extends StatelessWidget {
  const _PracticeCell({required this.controller, required this.r, required this.c});

  final PracticeController controller;
  final int r;
  final int c;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = controller.board[r][c];
    final isGiven = controller.given[r][c];
    final isLocked = controller.locked[r][c];
    final isSelected = controller.selectedRow == r && controller.selectedCol == c;
    final isHintCell = controller.hintCell == (r, c);
    final isHintArea = controller.hintArea.contains((r, c));

    Color background;
    if (isHintCell) {
      background = Colors.amber.withValues(alpha: 0.7);
    } else if (isSelected) {
      background = colors.primaryContainer;
    } else if (isHintArea) {
      background = Colors.amber.withValues(alpha: 0.2);
    } else if (controller.isRelated(r, c)) {
      background = colors.primary.withValues(alpha: 0.08);
    } else {
      background = colors.surface;
    }

    final textColor =
        isGiven ? colors.onSurface : (isLocked ? colors.primary : colors.secondary);

    return Container(
      color: background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(2),
      child: value != 0
          ? FittedBox(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  color: textColor,
                  fontWeight: isGiven ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            )
          : _NotesWidget(notes: controller.notes[r][c].toList()..sort()),
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText({required this.value, this.label, required this.color});

  final int value;
  final String? label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = label ?? (value == 0 ? '' : '$value');
    return FittedBox(
      child: Text(
        text,
        style: TextStyle(fontSize: 28, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _NotesWidget extends StatelessWidget {
  const _NotesWidget({required this.notes});

  final List<int> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: List.generate(3, (i) {
        return Expanded(
          child: Row(
            children: List.generate(3, (j) {
              final n = i * 3 + j + 1;
              return Expanded(
                child: Center(
                  child: notes.contains(n)
                      ? FittedBox(
                          child: Text(
                            '$n',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

