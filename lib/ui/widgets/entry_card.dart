import 'package:flutter/material.dart';

import 'package:sentiment/models/entry.dart';
import 'package:sentiment/ui/widgets/mood_chip.dart';

class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    required this.dateLabel,
    this.onTap,
  });

  final JournalEntry entry;
  final String dateLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateLabel, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                entry.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (entry.preMoodSelection != null ||
                  entry.postMoodSelection != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (entry.preMoodSelection != null)
                        MoodChip(
                          label: entry.preMoodSelection!.label,
                          selection: entry.preMoodSelection,
                          role: 'Before',
                        ),
                      if (entry.postMoodSelection != null)
                        MoodChip(
                          label: entry.postMoodSelection!.label,
                          selection: entry.postMoodSelection,
                          role: 'After',
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
