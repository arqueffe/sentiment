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
    final color = selection == null
        ? Theme.of(context).colorScheme.outline
        : emotionColor(context, selection!.primaryId);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            role == null ? label : '$role: $label',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: content,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: content,
      ),
    );
  }
}
