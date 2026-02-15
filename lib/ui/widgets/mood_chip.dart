import 'package:flutter/material.dart';

import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/ui/widgets/emotion_color.dart';

class MoodChip extends StatelessWidget {
  const MoodChip({
    super.key,
    required this.label,
    this.onTap,
    this.selection,
    this.role,
  });

  final String label;
  final VoidCallback? onTap;
  final EmotionSelection? selection;
  final String? role;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selection == null
        ? colorScheme.outline
        : emotionColor(context, selection!.primaryId);
    final hasRole = role != null && role!.trim().isNotEmpty;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasRole)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              role!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (hasRole) const SizedBox(width: 8),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );

    if (onTap == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: content,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: content,
      ),
    );
  }
}
