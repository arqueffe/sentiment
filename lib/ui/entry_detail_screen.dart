import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sentiment/models/entry.dart';
import 'package:sentiment/ui/widgets/mood_chip.dart';
import 'package:sentiment/ui/widgets/sentence_emotion_overlay.dart';
import 'package:sentiment/ui/widgets/settings_button.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.entry});

  static const _bodyLineSpacing = 2.5;
  static const _detailBadgeVerticalOffset = 6.0;

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry'),
        actions: const [SettingsButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMMd().add_Hm().format(entry.createdAt),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            SentenceEmotionOverlayText(
              text: entry.body,
              annotations: entry.sentenceEmotionAnnotations,
              textStyle: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: _bodyLineSpacing),
              strutStyle: const StrutStyle(
                height: _bodyLineSpacing,
                forceStrutHeight: true,
              ),
              badgeVerticalOffset: _detailBadgeVerticalOffset,
            ),
            const SizedBox(height: 24),
            if (entry.preMoodSelection != null) ...[
              Text('Before', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              MoodChip(
                label: entry.preMoodSelection!.label,
                selection: entry.preMoodSelection,
                role: 'Before',
              ),
              const SizedBox(height: 16),
            ],
            if (entry.postMoodSelection != null) ...[
              Text('After', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              MoodChip(
                label: entry.postMoodSelection!.label,
                selection: entry.postMoodSelection,
                role: 'After',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
