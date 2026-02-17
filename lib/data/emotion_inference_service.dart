import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

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
  static const String _modelDataAssetPath =
      'assets/models/bert-emotion.onnx.data';
  static const String _vocabAssetPath = 'bert-emotion/vocab.txt';
  static const String _configAssetPath = 'bert-emotion/config.json';
  static const int _maxTokens = 128;
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
  Map<String, int>? _vocab;
  List<String> _labelOrder = _defaultLabelOrder;

  bool get isReady => _session != null && _vocab != null;

  Future<void> initialize() async {
    if (isReady) {
      return;
    }
    _vocab ??= await _loadVocab();
    _labelOrder = await _loadLabelOrder();
    final modelPath = await _prepareModelFiles();
    _session ??= await _runtime.createSession(modelPath);
  }

  Future<String> _prepareModelFiles() async {
    final cacheDirectory = await getTemporaryDirectory();
    final modelFile = File(
      '${cacheDirectory.path}${Platform.pathSeparator}bert-emotion.onnx',
    );
    final modelDataFile = File(
      '${cacheDirectory.path}${Platform.pathSeparator}bert-emotion.onnx.data',
    );

    if (!await modelFile.exists()) {
      final modelBytes = await rootBundle.load(_modelAssetPath);
      await modelFile.writeAsBytes(
        modelBytes.buffer.asUint8List(),
        flush: true,
      );
    }

    if (!await modelDataFile.exists()) {
      final modelDataBytes = await rootBundle.load(_modelDataAssetPath);
      await modelDataFile.writeAsBytes(
        modelDataBytes.buffer.asUint8List(),
        flush: true,
      );
    }

    return modelFile.path;
  }

  Future<EmotionPrediction> classifySentence(String sentence) async {
    if (sentence.trim().isEmpty) {
      return _neutralPrediction;
    }

    try {
      final probabilities = await _runInference(_encodeSentence(sentence));
      if (probabilities.isEmpty) {
        return _neutralPrediction;
      }
      return _predictionFromProbabilities(probabilities);
    } catch (_) {
      return _neutralPrediction;
    }
  }

  Future<EmotionPrediction> classifyEntry(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return _neutralPrediction;
    }

    try {
      final chunks = _splitTextIntoChunks(normalized);
      if (chunks.isEmpty) {
        return _neutralPrediction;
      }

      final aggregate = List<double>.filled(_labelOrder.length, 0);
      var processedChunks = 0;

      for (final chunk in chunks) {
        final probabilities = await _runInference(_encodeSentence(chunk));
        if (probabilities.isEmpty) {
          continue;
        }
        for (var i = 0; i < aggregate.length && i < probabilities.length; i++) {
          aggregate[i] += probabilities[i];
        }
        processedChunks += 1;
      }

      if (processedChunks == 0) {
        return _neutralPrediction;
      }

      final averaged = aggregate
          .map((value) => value / processedChunks)
          .toList();
      final normalizedAveraged = _normalizeProbabilities(averaged);
      final prediction = _predictionFromProbabilities(normalizedAveraged);
      return EmotionPrediction(
        modelLabel: prediction.modelLabel,
        confidence: prediction.confidence,
        primaryEmotionId: prediction.primaryEmotionId,
        labelProbabilities: prediction.labelProbabilities,
        chunkCount: processedChunks,
      );
    } catch (_) {
      return _neutralPrediction;
    }
  }

  Future<List<double>> _runInference(List<int> encodedIds) async {
    if (!isReady) {
      await initialize();
    }
    if (!isReady) {
      return const [];
    }

    final encoded = Int64List.fromList(encodedIds);
    OrtValue? inputIds;
    OrtValue? attentionMask;
    OrtValue? tokenTypeIds;
    Map<String, OrtValue> outputs = {};

    try {
      inputIds = await OrtValue.fromList(encoded, [1, encoded.length]);
      attentionMask = await OrtValue.fromList(
        Int64List.fromList(List<int>.filled(encoded.length, 1)),
        [1, encoded.length],
      );
      tokenTypeIds = await OrtValue.fromList(
        Int64List.fromList(List<int>.filled(encoded.length, 0)),
        [1, encoded.length],
      );

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

  Future<List<String>> _loadLabelOrder() async {
    try {
      final configRaw = await rootBundle.loadString(_configAssetPath);
      final config = jsonDecode(configRaw) as Map<String, dynamic>;
      final idToLabel = config['id2label'] as Map<String, dynamic>?;
      if (idToLabel == null || idToLabel.isEmpty) {
        return _defaultLabelOrder;
      }
      final sorted = idToLabel.entries.toList()
        ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
      return sorted.map((entry) => entry.value.toString()).toList();
    } catch (_) {
      return _defaultLabelOrder;
    }
  }

  List<int> _encodeSentence(String sentence) {
    final vocab = _vocab ?? const <String, int>{};
    final clsId = vocab['[CLS]'] ?? 101;
    final sepId = vocab['[SEP]'] ?? 102;
    final unkId = vocab['[UNK]'] ?? 100;

    final tokenIds = <int>[clsId];

    final words =
        sentence.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim().split(' ')
          ..removeWhere((word) => word.isEmpty);

    for (final word in words) {
      if (tokenIds.length >= _maxTokens - 1) {
        break;
      }
      if (vocab.containsKey(word)) {
        tokenIds.add(vocab[word]!);
        continue;
      }

      final pieces = _wordPiece(word, vocab, unkId);
      for (final piece in pieces) {
        if (tokenIds.length >= _maxTokens - 1) {
          break;
        }
        tokenIds.add(piece);
      }
      if (tokenIds.length >= _maxTokens - 1) {
        break;
      }
    }

    tokenIds.add(sepId);
    return tokenIds;
  }

  List<int> _wordPiece(String word, Map<String, int> vocab, int unkId) {
    final output = <int>[];
    var start = 0;

    while (start < word.length) {
      String? currentPiece;
      var end = word.length;

      while (start < end) {
        var piece = word.substring(start, end);
        if (start > 0) {
          piece = '##$piece';
        }
        if (vocab.containsKey(piece)) {
          currentPiece = piece;
          break;
        }
        end -= 1;
      }

      if (currentPiece == null) {
        return [unkId];
      }

      output.add(vocab[currentPiece]!);
      start = end;
    }

    return output;
  }

  List<String> _splitTextIntoChunks(String text) {
    final vocab = _vocab ?? const <String, int>{};
    final unkId = vocab['[UNK]'] ?? 100;
    final words =
        text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim().split(' ')
          ..removeWhere((word) => word.isEmpty);

    if (words.isEmpty) {
      return const [];
    }

    final maxContentTokens = _maxTokens - 2;
    final chunks = <String>[];
    final currentWords = <String>[];
    var currentTokenCount = 0;

    for (final word in words) {
      final tokenCount = vocab.containsKey(word)
          ? 1
          : _wordPiece(word, vocab, unkId).length;

      if (currentWords.isNotEmpty &&
          currentTokenCount + tokenCount > maxContentTokens) {
        chunks.add(currentWords.join(' '));
        currentWords.clear();
        currentTokenCount = 0;
      }

      currentWords.add(word);
      currentTokenCount += tokenCount;

      if (currentTokenCount >= maxContentTokens) {
        chunks.add(currentWords.join(' '));
        currentWords.clear();
        currentTokenCount = 0;
      }
    }

    if (currentWords.isNotEmpty) {
      chunks.add(currentWords.join(' '));
    }

    return chunks;
  }

  List<double> _normalizeProbabilities(List<double> values) {
    if (values.isEmpty) {
      return values;
    }
    final sum = values.fold<double>(0, (acc, value) => acc + value);
    if (sum <= 0) {
      return List<double>.filled(values.length, 0);
    }
    return values.map((value) => value / sum).toList();
  }

  Future<Map<String, int>> _loadVocab() async {
    final content = await rootBundle.loadString(_vocabAssetPath);
    final lines = content.split(RegExp(r'\r?\n'));
    final vocab = <String, int>{};
    for (var i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isEmpty) {
        continue;
      }
      vocab[token] = i;
    }
    return vocab;
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
