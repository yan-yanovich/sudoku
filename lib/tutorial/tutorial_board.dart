import 'package:flutter/material.dart';

import 'lesson_data.dart';

/// Цвет подсветки клетки для разметки урока.
Color markBackground(ColorScheme s, MarkColor color) => switch (color) {
      MarkColor.focus => s.primary.withValues(alpha: 0.35),
      MarkColor.related => s.tertiary.withValues(alpha: 0.18),
      MarkColor.pattern => s.secondary.withValues(alpha: 0.30),
      MarkColor.remove => s.error.withValues(alpha: 0.25),
      MarkColor.success => Colors.green.withValues(alpha: 0.35),
    };


/// Доска 9×9 для уроков: пример (только просмотр) или практика (с нажатиями).
class TutorialBoard extends StatelessWidget {
  const TutorialBoard({
    super.key,
    required this.board,
    this.marks = const [],
    this.fixed,
    this.notes,
    this.solution,
    this.selectedRow,
    this.selectedCol,
    this.onCellTap,
  });

  /// Текущие значения (0 — пусто).
  final List<List<int>> board;

  /// Подсветка и подписи из урока.
  final List<Mark> marks;

  /// Какие клетки — исходные подсказки. Если null — все непустые.
  final List<List<bool>>? fixed;

  /// Кандидаты (заметки) по клеткам.
  final List<List<Set<int>>>? notes;

  /// Если задано — неверные цифры подсвечиваются красным.
  final List<List<int>>? solution;

  final int? selectedRow;
  final int? selectedCol;

  /// Если null — доска только для просмотра.
  final void Function(int row, int col)? onCellTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final markMap = <int, Mark>{
      for (final m in marks) m.row * 9 + m.col: m,
    };
    final selectedValue = (selectedRow != null && selectedCol != null)
        ? board[selectedRow!][selectedCol!]
        : 0;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: colors.onSurface),
        ),
        child: Column(
          children: List.generate(
            9,
            (r) => Expanded(
              child: Row(
                children: List.generate(
                  9,
                  (c) => Expanded(
                    child: _TutorialCell(
                      row: r,
                      col: c,
                      value: board[r][c],
                      isFixed: fixed?[r][c] ?? board[r][c] != 0,
                      isWrong: solution != null &&
                          board[r][c] != 0 &&
                          board[r][c] != solution![r][c],
                      isSelected: r == selectedRow && c == selectedCol,
                      selectedValue: selectedValue,
                      mark: markMap[r * 9 + c],
                      cellNotes: notes?[r][c] ?? const <int>{},
                      onTap: onCellTap == null ? null : () => onCellTap!(r, c),
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

class _TutorialCell extends StatelessWidget {
  const _TutorialCell({
    required this.row,
    required this.col,
    required this.value,
    required this.isFixed,
    required this.isWrong,
    required this.isSelected,
    required this.selectedValue,
    required this.mark,
    required this.cellNotes,
    required this.onTap,
  });

  final int row;
  final int col;
  final int value;
  final bool isFixed;
  final bool isWrong;
  final bool isSelected;
  final int selectedValue;
  final Mark? mark;
  final Set<int> cellNotes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color background = colors.surface;
    if (isSelected) {
      background = colors.primaryContainer;
    } else if (isWrong) {
      background = colors.errorContainer;
    } else if (mark?.color != null) {
      background = markBackground(mark!.color!, colors);
    } else if (value != 0 && value == selectedValue) {
      background = colors.primary.withValues(alpha: 0.2);
    }

    final thick = BorderSide(width: 2, color: colors.onSurface);
    final thin = BorderSide(width: 0.5, color: colors.outlineVariant);
    final right =
        col == 8 ? BorderSide.none : (col == 2 || col == 5 ? thick : thin);
    final bottom =
        row == 8 ? BorderSide.none : (row == 2 || row == 5 ? thick : thin);

    // Текст из разметки урока (например, ответ) имеет приоритет.
    final markText = mark?.text;
    final displayText = markText ?? (value != 0 ? '$value' : null);

    final textColor = markText != null
        ? Colors.green.shade700
        : isWrong
            ? colors.error
            : isFixed
                ? colors.onSurface
                : colors.primary;

    final candidateNotes = mark?.notes?.toSet() ?? cellNotes;

    Widget? content;
    if (displayText != null) {
      content = FittedBox(
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: 28,
            color: textColor,
            fontWeight: isFixed || markText != null
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      );
    } else if (candidateNotes.isNotEmpty) {
      content = _CellNotes(notes: candidateNotes, highlight: selectedValue);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(right: right, bottom: bottom),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.all(displayText == null ? 1 : 4),
        child: content,
      ),
    );
  }
}

class _CellNotes extends StatelessWidget {
  const _CellNotes({required this.notes, this.highlight = 0});

  final Set<int> notes;
  final int highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(3, (i) {
        return Expanded(
          child: Row(
            children: List.generate(3, (j) {
              final n = i * 3 + j + 1;
              final isHighlighted = n == highlight;
              return Expanded(
                child: Center(
                  child: notes.contains(n)
                      ? FittedBox(
                          child: Text(
                            '$n',
                            style: TextStyle(
                              fontSize: 12,
                              color: isHighlighted
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              fontWeight: isHighlighted
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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

/// Легенда цветов, использованных в примере.
class MarkLegend extends StatelessWidget {
  const MarkLegend({super.key, required this.marks});

  final List<Mark> marks;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final used = <MarkColor>{
      for (final m in marks)
        if (m.color != null) m.color!,
    }.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (used.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final c in used)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: markBackground(c, colors),
                  border: Border.all(color: colors.outline, width: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(c.legend, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}
