import 'package:flutter/material.dart';

import '../game/game_controller.dart';

class SudokuBoard extends StatelessWidget {
  const SudokuBoard({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 2, color: colors.onSurface)),
        child: Column(
          children: List.generate(
            9,
            (r) => Expanded(
              child: Row(
                children: List.generate(
                  9,
                  (c) => Expanded(child: _Cell(controller: controller, row: r, col: c)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.controller, required this.row, required this.col});

  final GameController controller;
  final int row;
  final int col;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final c = controller;
    final value = c.board[row][col];
    final isFixed = c.fixed[row][col];
    final isWrong = c.isWrong(row, col);
    final isSelected = c.selectedRow == row && c.selectedCol == col;
    final selectedValue = c.selectedValue;

    // Фон клетки (цвета из темы, поэтому работают и в тёмной)
    Color background = colors.surface;
    if (isSelected) {
      background = colors.primaryContainer;
    } else if (isWrong) {
      background = colors.errorContainer;
    } else if (value != 0 && value == selectedValue) {
      background = colors.primary.withValues(alpha: 0.25);
    } else if (c.isRelated(row, col)) {
      background = colors.primary.withValues(alpha: 0.08);
    }

    final textColor = isFixed
        ? colors.onSurface
        : isWrong
            ? colors.error
            : colors.primary;

    final thick = BorderSide(width: 2, color: colors.onSurface);
    final thin = BorderSide(width: 0.5, color: colors.outlineVariant);
    final right = col == 8 ? BorderSide.none : (col == 2 || col == 5 ? thick : thin);
    final bottom = row == 8 ? BorderSide.none : (row == 2 || row == 5 ? thick : thin);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => c.selectCell(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(right: right, bottom: bottom),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.all(value == 0 ? 1 : 4),
        child: value != 0
            ? FittedBox(
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 28,
                    color: textColor,
                    fontWeight: isFixed ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              )
            : _Notes(notes: c.notes[row][col], highlight: selectedValue),
      ),
    );
  }
}

/// Заметки: мини-сетка 3×3 с цифрами-кандидатами.
class _Notes extends StatelessWidget {
  const _Notes({required this.notes, required this.highlight});

  final Set<int> notes;
  final int highlight;

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
                              fontWeight:
                                  isHighlighted ? FontWeight.bold : FontWeight.normal,
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
