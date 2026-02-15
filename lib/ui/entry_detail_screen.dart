import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/models/entry.dart';
import 'package:sentiment/ui/widgets/emotion_color.dart';
import 'package:sentiment/ui/widgets/mood_chip.dart';
import 'package:sentiment/ui/widgets/settings_button.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.entry});

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
            _AnnotatedEntryBody(entry: entry),
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

class _AnnotatedEntryBody extends StatefulWidget {
  const _AnnotatedEntryBody({required this.entry});

  final JournalEntry entry;

  @override
  State<_AnnotatedEntryBody> createState() => _AnnotatedEntryBodyState();
}

class _AnnotatedEntryBodyState extends State<_AnnotatedEntryBody> {
  String? _hoveredEmotionLabel;

  void _setHoveredEmotionLabel(SentenceEmotionAnnotation? annotation) {
    final primaryEmotionId = annotation?.primaryEmotionId;
    final nextLabel = primaryEmotionId == null
        ? null
        : (EmotionCatalog.byId(primaryEmotionId)?.label ?? primaryEmotionId);
    if (nextLabel == _hoveredEmotionLabel || !mounted) {
      return;
    }
    setState(() {
      _hoveredEmotionLabel = nextLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge;
    final annotations = widget.entry.sentenceEmotionAnnotations
      ..sort((a, b) => a.start.compareTo(b.start));

    if (annotations.isEmpty) {
      return Text(widget.entry.body, style: baseStyle);
    }

    final children = <InlineSpan>[];
    var currentIndex = 0;
    for (final annotation in annotations) {
      if (annotation.start < currentIndex ||
          annotation.end > widget.entry.body.length) {
        continue;
      }
      if (annotation.start > currentIndex) {
        children.add(
          TextSpan(
            text: widget.entry.body.substring(currentIndex, annotation.start),
            style: baseStyle,
          ),
        );
      }

      final primaryEmotionId = annotation.primaryEmotionId;
      final sentenceStyle = primaryEmotionId == null
          ? baseStyle
          : baseStyle?.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: emotionColor(context, primaryEmotionId),
              decorationThickness: 2,
            );

      children.add(
        TextSpan(
          text: widget.entry.body.substring(annotation.start, annotation.end),
          style: sentenceStyle,
          mouseCursor: primaryEmotionId == null
              ? MouseCursor.defer
              : SystemMouseCursors.help,
          onEnter: primaryEmotionId == null
              ? null
              : (_) => _setHoveredEmotionLabel(annotation),
          onExit: primaryEmotionId == null
              ? null
              : (_) => _setHoveredEmotionLabel(null),
        ),
      );
      currentIndex = annotation.end;
    }

    if (currentIndex < widget.entry.body.length) {
      children.add(
        TextSpan(
          text: widget.entry.body.substring(currentIndex),
          style: baseStyle,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText.rich(TextSpan(style: baseStyle, children: children)),
        if (_hoveredEmotionLabel != null) ...[
          const SizedBox(height: 8),
          Text(
            'Hovered sentence emotion: $_hoveredEmotionLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
