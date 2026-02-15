import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sentiment/data/emotion_inference_service.dart';
import 'package:sentiment/data/emotion_label_mapper.dart';
import 'package:sentiment/models/entry.dart';

class SentenceEmotionState {
  const SentenceEmotionState({
    this.body = '',
    this.annotations = const [],
    this.counts = const {},
    this.isClassifying = false,
  });

  final String body;
  final List<SentenceEmotionAnnotation> annotations;
  final Map<String, int> counts;
  final bool isClassifying;

  SentenceEmotionState copyWith({
    String? body,
    List<SentenceEmotionAnnotation>? annotations,
    Map<String, int>? counts,
    bool? isClassifying,
  }) {
    return SentenceEmotionState(
      body: body ?? this.body,
      annotations: annotations ?? this.annotations,
      counts: counts ?? this.counts,
      isClassifying: isClassifying ?? this.isClassifying,
    );
  }
}

class SentenceEmotionController extends StateNotifier<SentenceEmotionState> {
  SentenceEmotionController({
    required EmotionInferenceService inferenceService,
    required EmotionLabelMapper labelMapper,
  }) : _inferenceService = inferenceService,
       _labelMapper = labelMapper,
       super(const SentenceEmotionState());

  final EmotionInferenceService _inferenceService;
  final EmotionLabelMapper _labelMapper;

  Timer? _debounce;

  void setBody(String body) {
    state = state.copyWith(body: body, isClassifying: true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final completed = _extractCompletedSentences(state.body);
      final annotations = <SentenceEmotionAnnotation>[];

      for (final span in completed) {
        final sentence = span.text.trim();
        if (sentence.isEmpty) {
          continue;
        }
        final prediction = await _inferenceService.classifySentence(sentence);
        annotations.add(
          SentenceEmotionAnnotation(
            start: span.start,
            end: span.end,
            sentence: sentence,
            modelLabel: prediction.modelLabel,
            primaryEmotionId: prediction.primaryEmotionId,
            confidence: prediction.confidence,
          ),
        );
      }

      final counts = _buildCounts(annotations);
      state = state.copyWith(
        annotations: annotations,
        counts: counts,
        isClassifying: false,
      );
    });
  }

  void reset() {
    _debounce?.cancel();
    state = const SentenceEmotionState();
  }

  Map<String, int> _buildCounts(List<SentenceEmotionAnnotation> annotations) {
    final counts = <String, int>{};
    for (final annotation in annotations) {
      if (!_labelMapper.isCountable(annotation)) {
        continue;
      }
      final primaryId = annotation.primaryEmotionId;
      if (primaryId == null) {
        continue;
      }
      counts.update(primaryId, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  List<_SentenceSpan> _extractCompletedSentences(String body) {
    final spans = <_SentenceSpan>[];
    final regex = RegExp(r'[^.!?\n]+[.!?](?=\s|\n|$)');
    for (final match in regex.allMatches(body)) {
      final text = match.group(0);
      if (text == null || text.trim().isEmpty) {
        continue;
      }
      spans.add(_SentenceSpan(start: match.start, end: match.end, text: text));
    }
    return spans;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class _SentenceSpan {
  const _SentenceSpan({
    required this.start,
    required this.end,
    required this.text,
  });

  final int start;
  final int end;
  final String text;
}
