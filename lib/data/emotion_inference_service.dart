import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_bert_tokenizer/dart_bert_tokenizer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'package:sentiment/data/emotion_label_mapper.dart';

class EmotionPrediction {
  const EmotionPrediction({
    required this.modelLabel,
    required this.confidence,
    required this.primaryEmotionId,
    this.labelProbabilities = const {},
    this.chunkCount = 1,
  });

  final String modelLabel;
  final double confidence;
  final String? primaryEmotionId;
  final Map<String, double> labelProbabilities;
  final int chunkCount;
}

class EmotionInferenceService {
  EmotionInferenceService({
    required EmotionLabelMapper labelMapper,
    OnnxRuntime? runtime,
  }) : _labelMapper = labelMapper,
       _runtime = runtime ?? OnnxRuntime();

  static const String _modelAssetPath = 'assets/models/bert-emotion.onnx';
  static const String _webModelAssetPath =
      'assets/models/bert-emotion_web.onnx';
  static const String _vocabAssetPath = 'bert-emotion/vocab.txt';
  static const String _configAssetPath = 'bert-emotion/config.json';
  static const int _defaultMaxSequenceLength = 512;
  static const EmotionPrediction _neutralPrediction = EmotionPrediction(
    modelLabel: EmotionLabelMapper.neutralLabel,
    confidence: 1,
    primaryEmotionId: null,
    labelProbabilities: {EmotionLabelMapper.neutralLabel: 1},
  );

  static const List<String> _defaultLabelOrder = [
    'sadness',
    'anger',
    'love',
    'surprise',
    'fear',
    'happiness',
    'neutral',
    'disgust',
    'shame',
    'guilt',
    'confusion',
    'desire',
    'sarcasm',
  ];

  final EmotionLabelMapper _labelMapper;
  final OnnxRuntime _runtime;

  OrtSession? _session;
  WordPieceTokenizer? _tokenizer;
  WordPieceTokenizer? _entryChunkTokenizer;
  int _maxSequenceLength = _defaultMaxSequenceLength;
  List<String> _labelOrder = _defaultLabelOrder;

  bool get isReady =>
      _session != null && _tokenizer != null && _entryChunkTokenizer != null;

  Future<void> initialize() async {
    if (isReady) {
      return;
    }

    _log('initialize() started (isWeb: $kIsWeb)');

    final config = await _loadConfig();
    _maxSequenceLength = _resolveMaxSequenceLength(config);
    _labelOrder = _resolveLabelOrder(config);
    _log(
      'config loaded (maxSequenceLength: $_maxSequenceLength, labels: ${_labelOrder.length})',
    );

    final vocabContent = await rootBundle.loadString(_vocabAssetPath);
    final vocab = Vocabulary.fromString(vocabContent);
    _log('vocab loaded (size: ${vocab.size})');
    final tokenizer = WordPieceTokenizer(vocab: vocab);
    tokenizer.enableTruncation(maxLength: _maxSequenceLength);
    tokenizer.enablePadding(length: _maxSequenceLength);
    final entryChunkTokenizer = WordPieceTokenizer(vocab: vocab);

    final OrtSession session;
    if (kIsWeb) {
      session = await _createWebSession();
    } else {
      session = await _runtime.createSessionFromAsset(_modelAssetPath);
    }

    _tokenizer = tokenizer;
    _entryChunkTokenizer = entryChunkTokenizer;
    _session = session;
    _log('initialize() completed successfully');
  }

  Future<EmotionPrediction> classifySentence(String sentence) async {
    if (sentence.trim().isEmpty) {
      return _neutralPrediction;
    }

    try {
      if (!isReady) {
        await initialize();
      }
      if (!isReady) {
        return _neutralPrediction;
      }

      final tokenized = _tokenize(sentence);
      final probabilities = await _runInference(tokenized);
      if (probabilities.isEmpty) {
        return _neutralPrediction;
      }
      return _predictionFromProbabilities(probabilities);
    } catch (error, stackTrace) {
      _logError('classifySentence() failed', error, stackTrace);
      return _neutralPrediction;
    }
  }

  Future<EmotionPrediction> classifyEntry(String text) async {
    final entryText = text.trim();
    if (entryText.isEmpty) {
      return const EmotionPrediction(
        modelLabel: '',
        confidence: 0,
        primaryEmotionId: null,
        chunkCount: 0,
      );
    }

    try {
      if (!isReady) {
        await initialize();
      }
      if (!isReady) {
        return _neutralPrediction;
      }

      final chunks = _splitEntryIntoMaxTokenChunks(entryText);
      if (chunks.isEmpty) {
        return _neutralPrediction;
      }

      final summedProbabilities = List<double>.filled(_labelOrder.length, 0);
      var validChunkCount = 0;

      for (final chunk in chunks) {
        final tokenized = _tokenize(chunk);
        final probabilities = await _runInference(tokenized);
        if (probabilities.isEmpty) {
          continue;
        }
        validChunkCount++;
        for (
          var i = 0;
          i < probabilities.length && i < summedProbabilities.length;
          i++
        ) {
          summedProbabilities[i] += probabilities[i];
        }
      }

      if (validChunkCount == 0) {
        return _neutralPrediction;
      }

      final averaged = summedProbabilities
          .map((value) => value / validChunkCount)
          .toList(growable: false);
      final basePrediction = _predictionFromProbabilities(averaged);
      return EmotionPrediction(
        modelLabel: basePrediction.modelLabel,
        confidence: basePrediction.confidence,
        primaryEmotionId: basePrediction.primaryEmotionId,
        labelProbabilities: basePrediction.labelProbabilities,
        chunkCount: validChunkCount,
      );
    } catch (error, stackTrace) {
      _logError('classifyEntry() failed', error, stackTrace);
      return _neutralPrediction;
    }
  }

  List<String> _splitEntryIntoMaxTokenChunks(String text) {
    final chunks = <String>[];
    var start = 0;

    while (start < text.length) {
      while (start < text.length && _isWhitespace(text.codeUnitAt(start))) {
        start++;
      }
      if (start >= text.length) {
        break;
      }

      var low = start + 1;
      var high = text.length;
      var bestEnd = start;

      while (low <= high) {
        final mid = (low + high) >> 1;
        final candidate = text.substring(start, mid).trim();
        if (candidate.isEmpty) {
          low = mid + 1;
          continue;
        }

        final tokenCount = _entryChunkTokenizer!.encode(candidate).ids.length;
        if (tokenCount <= _maxSequenceLength) {
          bestEnd = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      if (bestEnd <= start) {
        break;
      }

      var chunkEnd = bestEnd;
      if (chunkEnd < text.length) {
        var backtrack = chunkEnd;
        while (backtrack > start &&
            !_isWhitespace(text.codeUnitAt(backtrack - 1))) {
          backtrack--;
        }
        if (backtrack > start) {
          chunkEnd = backtrack;
        }
      }

      final chunk = text.substring(start, chunkEnd).trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }

      if (chunkEnd <= start) {
        break;
      }
      start = chunkEnd;
    }

    return chunks;
  }

  bool _isWhitespace(int codeUnit) {
    return codeUnit == 0x20 ||
        codeUnit == 0x09 ||
        codeUnit == 0x0A ||
        codeUnit == 0x0D;
  }

  Future<List<double>> _runInference(
    _EmotionTokenizationResult tokenized,
  ) async {
    if (!isReady) {
      await initialize();
    }
    if (!isReady) {
      return const [];
    }

    OrtValue? inputIds;
    OrtValue? attentionMask;
    OrtValue? tokenTypeIds;
    Map<String, OrtValue> outputs = {};

    try {
      inputIds = await OrtValue.fromList(tokenized.inputIds, [
        1,
        tokenized.inputIds.length,
      ]);
      attentionMask = await OrtValue.fromList(tokenized.attentionMask, [
        1,
        tokenized.attentionMask.length,
      ]);
      tokenTypeIds = await OrtValue.fromList(tokenized.tokenTypeIds, [
        1,
        tokenized.tokenTypeIds.length,
      ]);

      outputs = await _session!.run({
        'input_ids': inputIds,
        'attention_mask': attentionMask,
        'token_type_ids': tokenTypeIds,
      });

      final logitsTensor = outputs['logits'] ?? outputs.values.first;
      final logits = (await logitsTensor.asFlattenedList())
          .map((value) => (value as num).toDouble())
          .toList();
      if (logits.isEmpty) {
        return const [];
      }
      return _softmax(logits);
    } catch (error, stackTrace) {
      _logError(
        '_runInference() failed (tokenCount: ${tokenized.inputIds.length})',
        error,
        stackTrace,
      );
      rethrow;
    } finally {
      await inputIds?.dispose();
      await attentionMask?.dispose();
      await tokenTypeIds?.dispose();
      for (final tensor in outputs.values) {
        await tensor.dispose();
      }
    }
  }

  EmotionPrediction _predictionFromProbabilities(List<double> probabilities) {
    if (probabilities.isEmpty) {
      return _neutralPrediction;
    }

    final index = _argmax(probabilities);
    final modelLabel = _labelOrder[index.clamp(0, _labelOrder.length - 1)];
    final distribution = <String, double>{};
    for (var i = 0; i < probabilities.length && i < _labelOrder.length; i++) {
      distribution[_labelOrder[i]] = probabilities[i];
    }

    return EmotionPrediction(
      modelLabel: modelLabel,
      confidence: probabilities[index],
      primaryEmotionId: _labelMapper.mapPrimaryId(modelLabel),
      labelProbabilities: distribution,
    );
  }

  _EmotionTokenizationResult _tokenize(String sentence) {
    final encoding = _tokenizer!.encode(sentence.trim());
    return _EmotionTokenizationResult(
      inputIds: Int32List.fromList(
        encoding.ids.map((value) => value.toInt()).toList(),
      ),
      attentionMask: Int32List.fromList(
        encoding.attentionMask.map((value) => value.toInt()).toList(),
      ),
      tokenTypeIds: Int32List.fromList(
        encoding.typeIds.map((value) => value.toInt()).toList(),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadConfig() async {
    try {
      final configRaw = await rootBundle.loadString(_configAssetPath);
      return jsonDecode(configRaw) as Map<String, dynamic>;
    } catch (error, stackTrace) {
      _logError('_loadConfig() failed, using defaults', error, stackTrace);
      return const <String, dynamic>{};
    }
  }

  Future<OrtSession> _createWebSession() async {
    final candidates = <String>[
      // Canonical Flutter web asset URL for an asset key that already starts with `assets/`.
      'assets/$_webModelAssetPath',
      // Some static servers are configured from a different root and expose this path directly.
      _webModelAssetPath,
    ];

    Object? lastError;
    for (final candidate in candidates) {
      try {
        _log('trying web model URL: $candidate');
        return await _runtime.createSession(candidate);
      } catch (error, stackTrace) {
        _logError(
          'web session create failed for URL: $candidate',
          error,
          stackTrace,
        );
        lastError = error;
      }
    }
    throw StateError('Unable to load web ONNX model: $lastError');
  }

  void _log(String message) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[EmotionInferenceService] $message');
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[EmotionInferenceService] $message');
    debugPrint('[EmotionInferenceService] error: $error');
    debugPrint('[EmotionInferenceService] stackTrace: $stackTrace');
  }

  int _resolveMaxSequenceLength(Map<String, dynamic> config) {
    final maxPositionEmbeddings = config['max_position_embeddings'];
    if (maxPositionEmbeddings is int && maxPositionEmbeddings > 0) {
      return maxPositionEmbeddings;
    }
    return _defaultMaxSequenceLength;
  }

  List<String> _resolveLabelOrder(Map<String, dynamic> config) {
    final idToLabel = config['id2label'] as Map<String, dynamic>?;
    if (idToLabel == null || idToLabel.isEmpty) {
      return _defaultLabelOrder;
    }
    final sorted = idToLabel.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    return sorted.map((entry) => entry.value.toString()).toList();
  }

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
    _tokenizer = null;
    _entryChunkTokenizer = null;
  }

  int _argmax(List<double> values) {
    var maxIndex = 0;
    var maxValue = values.first;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > maxValue) {
        maxValue = values[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  List<double> _softmax(List<double> values) {
    final maxLogit = values.reduce(max);
    final exp = values
        .map((value) => pow(e, value - maxLogit).toDouble())
        .toList();
    final sum = exp.fold<double>(0, (acc, value) => acc + value);
    if (sum == 0) {
      return List<double>.filled(values.length, 0);
    }
    return exp.map((value) => value / sum).toList();
  }
}

class _EmotionTokenizationResult {
  const _EmotionTokenizationResult({
    required this.inputIds,
    required this.attentionMask,
    required this.tokenTypeIds,
  });

  final Int32List inputIds;
  final Int32List attentionMask;
  final Int32List tokenTypeIds;
}
