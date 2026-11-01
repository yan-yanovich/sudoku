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
