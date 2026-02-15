import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'package:sentiment/data/emotion_label_mapper.dart';

class EmotionPrediction {
  const EmotionPrediction({
    required this.modelLabel,
    required this.confidence,
    required this.primaryEmotionId,
  });

  final String modelLabel;
  final double confidence;
  final String? primaryEmotionId;
}

class EmotionInferenceService {
  EmotionInferenceService({
    required EmotionLabelMapper labelMapper,
    OnnxRuntime? runtime,
  }) : _labelMapper = labelMapper,
       _runtime = runtime ?? OnnxRuntime();

  static const String _modelAssetPath = 'assets/models/bert-emotion.onnx';
  static const String _vocabAssetPath = 'bert-emotion/vocab.txt';
  static const String _configAssetPath = 'bert-emotion/config.json';

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
    _session ??= await _runtime.createSessionFromAsset(_modelAssetPath);
  }

  Future<EmotionPrediction> classifySentence(String sentence) async {
    if (sentence.trim().isEmpty) {
      return const EmotionPrediction(
        modelLabel: EmotionLabelMapper.neutralLabel,
        confidence: 1,
        primaryEmotionId: null,
      );
    }

    try {
      if (!isReady) {
        await initialize();
      }

      if (!isReady) {
        return const EmotionPrediction(
          modelLabel: EmotionLabelMapper.neutralLabel,
          confidence: 1,
          primaryEmotionId: null,
        );
      }

      final encoded = Int64List.fromList(_encodeSentence(sentence));
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
          return const EmotionPrediction(
            modelLabel: EmotionLabelMapper.neutralLabel,
            confidence: 1,
            primaryEmotionId: null,
          );
        }

        final index = _argmax(logits);
        final probabilities = _softmax(logits);
        final modelLabel = _labelOrder[index.clamp(0, _labelOrder.length - 1)];

        return EmotionPrediction(
          modelLabel: modelLabel,
          confidence: probabilities[index],
          primaryEmotionId: _labelMapper.mapPrimaryId(modelLabel),
        );
      } finally {
        await inputIds?.dispose();
        await attentionMask?.dispose();
        await tokenTypeIds?.dispose();
        for (final tensor in outputs.values) {
          await tensor.dispose();
        }
      }
    } catch (_) {
      return const EmotionPrediction(
        modelLabel: EmotionLabelMapper.neutralLabel,
        confidence: 1,
        primaryEmotionId: null,
      );
    }
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

    const maxTokens = 128;
    final tokenIds = <int>[clsId];

    final words =
        sentence.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim().split(' ')
          ..removeWhere((word) => word.isEmpty);

    for (final word in words) {
      if (tokenIds.length >= maxTokens - 1) {
        break;
      }
      if (vocab.containsKey(word)) {
        tokenIds.add(vocab[word]!);
        continue;
      }

      final pieces = _wordPiece(word, vocab, unkId);
      tokenIds.addAll(pieces);
      if (tokenIds.length >= maxTokens - 1) {
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
