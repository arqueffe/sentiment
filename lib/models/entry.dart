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

@HiveType(typeId: 2)
class JournalEntry extends HiveObject {
  JournalEntry({
    required this.id,
    required this.body,
    required this.createdAt,
    this.preMood,
    this.postMood,
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

  EmotionSelection? get preMoodSelection => preMood?.toDomain();
  EmotionSelection? get postMoodSelection => postMood?.toDomain();

  JournalEntry copyWith({
    String? body,
    DateTime? createdAt,
    EmotionSelection? preMood,
    EmotionSelection? postMood,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'preMood': _moodToJson(preMoodSelection),
      'postMood': _moodToJson(postMoodSelection),
    };
  }

  static JournalEntry fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      preMood: _moodFromJson(json['preMood'] as Map<String, dynamic>?),
      postMood: _moodFromJson(json['postMood'] as Map<String, dynamic>?),
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
    return JournalEntry(
      id: id,
      body: body,
      createdAt: createdAt,
      preMood: preMood,
      postMood: postMood,
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
  }
}
