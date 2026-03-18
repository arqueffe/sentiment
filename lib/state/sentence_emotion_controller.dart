import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sentiment/data/emotion_inference_service.dart';
import 'package:sentiment/data/emotion_label_mapper.dart';
import 'package:sentiment/models/entry.dart';

class SentenceEmotionState {
  const SentenceEmotionState({
    this.body = '',
    this.annotations = const [],
    this.counts = const {},
    this.overallModelLabel = '',
    this.overallEmotionConfidence,
    this.overallEmotionChunkCount = 0,
    this.overallDistribution = const {},
    this.isClassifying = false,
  });

  final String body;
  final List<SentenceEmotionAnnotation> annotations;
  final Map<String, int> counts;
  final String overallModelLabel;
  final double? overallEmotionConfidence;
  final int overallEmotionChunkCount;
  final Map<String, double> overallDistribution;
  final bool isClassifying;

  SentenceEmotionState copyWith({
    String? body,
    List<SentenceEmotionAnnotation>? annotations,
    Map<String, int>? counts,
    String? overallModelLabel,
    double? overallEmotionConfidence,
    int? overallEmotionChunkCount,
    Map<String, double>? overallDistribution,
    bool? isClassifying,
  }) {
    return SentenceEmotionState(
      body: body ?? this.body,
      annotations: annotations ?? this.annotations,
      counts: counts ?? this.counts,
      overallModelLabel: overallModelLabel ?? this.overallModelLabel,
      overallEmotionConfidence:
          overallEmotionConfidence ?? this.overallEmotionConfidence,
      overallEmotionChunkCount:
          overallEmotionChunkCount ?? this.overallEmotionChunkCount,
      overallDistribution: overallDistribution ?? this.overallDistribution,
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
  int _requestSerial = 0;
  Future<void> _processing = Future.value();

  void setBody(String body) {
    state = state.copyWith(
      body: body,
      isClassifying: true,
      overallModelLabel: '',
      overallEmotionChunkCount: 0,
      overallDistribution: const {},
    );
    _debounce?.cancel();
    final requestId = ++_requestSerial;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      _processing = _classifySentences(
        targetBody: body,
        requestId: requestId,
        includeOverall: false,
      );
      await _processing;
    });
  }

  Future<void> prepareForNext(String body) async {
    _debounce?.cancel();
    if (state.body != body) {
      state = state.copyWith(body: body);
    }
    final requestId = ++_requestSerial;
    _processing = _classifySentences(
      targetBody: body,
      requestId: requestId,
      includeOverall: true,
    );
    await _processing;
  }

  Future<void> _classifySentences({
    required String targetBody,
    required int requestId,
    required bool includeOverall,
  }) async {
    final previousState = state;
    final completed = _extractCompletedSentences(targetBody);
    final annotations = <SentenceEmotionAnnotation>[];
    final cachedPredictionsBySentence = _buildCachedPredictions(
      previousState.annotations,
    );

    for (final span in completed) {
      final sentence = span.text.trim();
      if (sentence.isEmpty) {
        continue;
      }
      final cached = cachedPredictionsBySentence[sentence];
      final cachedPrediction = cached == null || cached.isEmpty
          ? null
          : cached.removeFirst();
      final prediction =
          cachedPrediction ??
          await _inferenceService.classifySentence(sentence);
      if (requestId != _requestSerial) {
        return;
      }
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

    if (requestId != _requestSerial || state.body != targetBody) {
      return;
    }

    final counts = _buildCounts(annotations);
    var overallSummary = const _OverallEmotionSummary(
      modelLabel: '',
      confidence: null,
      chunkCount: 0,
      distribution: {},
    );
    if (includeOverall) {
      final entryPrediction = await _inferenceService.classifyEntry(targetBody);
      if (requestId != _requestSerial || state.body != targetBody) {
        return;
      }
      overallSummary = _OverallEmotionSummary(
        modelLabel: entryPrediction.modelLabel,
        confidence: entryPrediction.confidence,
        chunkCount: entryPrediction.chunkCount,
        distribution: entryPrediction.labelProbabilities,
      );
    }

    state = state.copyWith(
      annotations: annotations,
      counts: counts,
      overallModelLabel: overallSummary.modelLabel,
      overallEmotionConfidence: overallSummary.confidence,
      overallEmotionChunkCount: overallSummary.chunkCount,
      overallDistribution: overallSummary.distribution,
      isClassifying: false,
    );
  }

  void reset() {
    _debounce?.cancel();
    _requestSerial++;
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

  Map<String, Queue<EmotionPrediction>> _buildCachedPredictions(
    List<SentenceEmotionAnnotation> annotations,
  ) {
    final cache = <String, Queue<EmotionPrediction>>{};
    for (final annotation in annotations) {
      final sentence = annotation.sentence.trim();
      if (sentence.isEmpty) {
        continue;
      }
      final bucket = cache.putIfAbsent(sentence, Queue.new);
      bucket.add(
        EmotionPrediction(
          modelLabel: annotation.modelLabel,
          primaryEmotionId: annotation.primaryEmotionId,
          confidence: annotation.confidence,
        ),
      );
    }
    return cache;
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

class _OverallEmotionSummary {
  const _OverallEmotionSummary({
    required this.modelLabel,
    required this.confidence,
    required this.chunkCount,
    required this.distribution,
  });

  final String modelLabel;
  final double? confidence;
  final int chunkCount;
  final Map<String, double> distribution;
}
