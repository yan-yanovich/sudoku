import 'package:flutter/material.dart';

import '../game/game_controller.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(icon: Icons.undo, label: 'Отмена', onTap: c.undo),
            _ActionButton(
                icon: Icons.backspace_outlined, label: 'Стереть', onTap: c.erase),
            _ActionButton(
              icon: Icons.edit_outlined,
              label: c.notesMode ? 'Заметки: вкл' : 'Заметки',
              active: c.notesMode,
              onTap: c.toggleNotesMode,
            ),
            _ActionButton(
              icon: Icons.lightbulb_outline,
              label: 'Подсказка (${c.hintsLeft})',
              onTap: c.hintsLeft > 0 ? () => _handleHint(context, c) : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(9, (i) {
            final number = i + 1;
            final remaining = c.remainingCount(number);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _NumberButton(
                  number: number,
                  remaining: remaining,
                  notesMode: c.notesMode,
                  onTap: remaining > 0 ? () => c.enterNumber(number) : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _handleHint(BuildContext context, GameController c) {
    if (c.selectedRow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите ячейку для подсказки'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    c.hint();
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
                  fontSize: 24,
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
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
