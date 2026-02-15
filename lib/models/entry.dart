import 'package:hive/hive.dart';

import 'package:sentiment/models/emotion.dart';

@HiveType(typeId: 1)
class EmotionSelectionHive extends HiveObject {
  EmotionSelectionHive({required this.primaryId, this.secondaryId});

  @HiveField(0)
  final String primaryId;

  @HiveField(1)
  final String? secondaryId;

  EmotionSelection toDomain() =>
      EmotionSelection(primaryId: primaryId, secondaryId: secondaryId);

  static EmotionSelectionHive fromDomain(EmotionSelection selection) {
    return EmotionSelectionHive(
      primaryId: selection.primaryId,
      secondaryId: selection.secondaryId,
    );
  }
}

class SentenceEmotionAnnotation {
  const SentenceEmotionAnnotation({
    required this.start,
    required this.end,
    required this.sentence,
    required this.modelLabel,
    required this.confidence,
    this.primaryEmotionId,
  });

  final int start;
  final int end;
  final String sentence;
  final String modelLabel;
  final String? primaryEmotionId;
  final double confidence;
}

@HiveType(typeId: 3)
class SentenceEmotionAnnotationHive extends HiveObject {
  SentenceEmotionAnnotationHive({
    required this.start,
    required this.end,
    required this.sentence,
    required this.modelLabel,
    required this.confidence,
    this.primaryEmotionId,
  });

  @HiveField(0)
  final int start;

  @HiveField(1)
  final int end;

  @HiveField(2)
  final String sentence;

  @HiveField(3)
  final String modelLabel;

  @HiveField(4)
  final String? primaryEmotionId;

  @HiveField(5)
  final double confidence;

  SentenceEmotionAnnotation toDomain() {
    return SentenceEmotionAnnotation(
      start: start,
      end: end,
      sentence: sentence,
      modelLabel: modelLabel,
      primaryEmotionId: primaryEmotionId,
      confidence: confidence,
    );
  }

  static SentenceEmotionAnnotationHive fromDomain(
    SentenceEmotionAnnotation annotation,
  ) {
    return SentenceEmotionAnnotationHive(
      start: annotation.start,
      end: annotation.end,
      sentence: annotation.sentence,
      modelLabel: annotation.modelLabel,
      primaryEmotionId: annotation.primaryEmotionId,
      confidence: annotation.confidence,
    );
  }
}

@HiveType(typeId: 2)
class JournalEntry extends HiveObject {
  JournalEntry({
    required this.id,
    required this.body,
    required this.createdAt,
    this.preMood,
    this.postMood,
    this.sentenceAnnotations = const [],
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String body;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final EmotionSelectionHive? preMood;

  @HiveField(4)
  final EmotionSelectionHive? postMood;

  @HiveField(5)
  final List<SentenceEmotionAnnotationHive> sentenceAnnotations;

  EmotionSelection? get preMoodSelection => preMood?.toDomain();
  EmotionSelection? get postMoodSelection => postMood?.toDomain();
  List<SentenceEmotionAnnotation> get sentenceEmotionAnnotations {
    return sentenceAnnotations
        .map((annotation) => annotation.toDomain())
        .toList();
  }

  JournalEntry copyWith({
    String? body,
    DateTime? createdAt,
    EmotionSelection? preMood,
    EmotionSelection? postMood,
    List<SentenceEmotionAnnotation>? sentenceAnnotations,
  }) {
    return JournalEntry(
      id: id,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      preMood: preMood == null
          ? this.preMood
          : EmotionSelectionHive.fromDomain(preMood),
      postMood: postMood == null
          ? this.postMood
          : EmotionSelectionHive.fromDomain(postMood),
      sentenceAnnotations: sentenceAnnotations == null
          ? this.sentenceAnnotations
          : sentenceAnnotations
                .map(SentenceEmotionAnnotationHive.fromDomain)
                .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'preMood': _moodToJson(preMoodSelection),
      'postMood': _moodToJson(postMoodSelection),
      'sentenceAnnotations': sentenceEmotionAnnotations
          .map(_annotationToJson)
          .toList(),
    };
  }

  static JournalEntry fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      preMood: _moodFromJson(json['preMood'] as Map<String, dynamic>?),
      postMood: _moodFromJson(json['postMood'] as Map<String, dynamic>?),
      sentenceAnnotations:
          (json['sentenceAnnotations'] as List<dynamic>? ?? const [])
              .map((item) => _annotationFromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }

  static Map<String, dynamic>? _moodToJson(EmotionSelection? mood) {
    if (mood == null) {
      return null;
    }
    return {'primaryId': mood.primaryId, 'secondaryId': mood.secondaryId};
  }

  static EmotionSelectionHive? _moodFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return EmotionSelectionHive(
      primaryId: json['primaryId'] as String,
      secondaryId: json['secondaryId'] as String?,
    );
  }

  static Map<String, dynamic> _annotationToJson(
    SentenceEmotionAnnotation annotation,
  ) {
    return {
      'start': annotation.start,
      'end': annotation.end,
      'sentence': annotation.sentence,
      'modelLabel': annotation.modelLabel,
      'primaryEmotionId': annotation.primaryEmotionId,
      'confidence': annotation.confidence,
    };
  }

  static SentenceEmotionAnnotationHive _annotationFromJson(
    Map<String, dynamic> json,
  ) {
    return SentenceEmotionAnnotationHive(
      start: json['start'] as int,
      end: json['end'] as int,
      sentence: json['sentence'] as String,
      modelLabel: json['modelLabel'] as String,
      primaryEmotionId: json['primaryEmotionId'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class EmotionSelectionAdapter extends TypeAdapter<EmotionSelectionHive> {
  @override
  final int typeId = 1;

  @override
  EmotionSelectionHive read(BinaryReader reader) {
    final primaryId = reader.readString();
    final secondaryId = reader.readBool() ? reader.readString() : null;
    return EmotionSelectionHive(primaryId: primaryId, secondaryId: secondaryId);
  }

  @override
  void write(BinaryWriter writer, EmotionSelectionHive obj) {
    writer.writeString(obj.primaryId);
    writer.writeBool(obj.secondaryId != null);
    if (obj.secondaryId != null) {
      writer.writeString(obj.secondaryId!);
    }
  }
}

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 2;

  @override
  JournalEntry read(BinaryReader reader) {
    final id = reader.readString();
    final body = reader.readString();
    final createdAt = DateTime.parse(reader.readString());
    final preMood = reader.readBool()
        ? reader.read() as EmotionSelectionHive
        : null;
    final postMood = reader.readBool()
        ? reader.read() as EmotionSelectionHive
        : null;
    final hasAnnotations = _tryRead(reader, reader.readBool) ?? false;
    final sentenceAnnotations = hasAnnotations
        ? (_tryRead(
                reader,
                () => (reader.read() as List)
                    .cast<SentenceEmotionAnnotationHive>(),
              ) ??
              const <SentenceEmotionAnnotationHive>[])
        : const <SentenceEmotionAnnotationHive>[];
    return JournalEntry(
      id: id,
      body: body,
      createdAt: createdAt,
      preMood: preMood,
      postMood: postMood,
      sentenceAnnotations: sentenceAnnotations,
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.body);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeBool(obj.preMood != null);
    if (obj.preMood != null) {
      writer.write(obj.preMood!);
    }
    writer.writeBool(obj.postMood != null);
    if (obj.postMood != null) {
      writer.write(obj.postMood!);
    }
    writer.writeBool(obj.sentenceAnnotations.isNotEmpty);
    if (obj.sentenceAnnotations.isNotEmpty) {
      writer.write(obj.sentenceAnnotations);
    }
  }

  T? _tryRead<T>(BinaryReader reader, T Function() fn) {
    try {
      return fn();
    } catch (_) {
      return null;
    }
  }
}

class SentenceEmotionAnnotationAdapter
    extends TypeAdapter<SentenceEmotionAnnotationHive> {
  @override
  final int typeId = 3;

  @override
  SentenceEmotionAnnotationHive read(BinaryReader reader) {
    final start = reader.readInt();
    final end = reader.readInt();
    final sentence = reader.readString();
    final modelLabel = reader.readString();
    final primaryEmotionId = reader.readBool() ? reader.readString() : null;
    final confidence = reader.readDouble();
    return SentenceEmotionAnnotationHive(
      start: start,
      end: end,
      sentence: sentence,
      modelLabel: modelLabel,
      primaryEmotionId: primaryEmotionId,
      confidence: confidence,
    );
  }

  @override
  void write(BinaryWriter writer, SentenceEmotionAnnotationHive obj) {
    writer.writeInt(obj.start);
    writer.writeInt(obj.end);
    writer.writeString(obj.sentence);
    writer.writeString(obj.modelLabel);
    writer.writeBool(obj.primaryEmotionId != null);
    if (obj.primaryEmotionId != null) {
      writer.writeString(obj.primaryEmotionId!);
    }
    writer.writeDouble(obj.confidence);
  }
}
