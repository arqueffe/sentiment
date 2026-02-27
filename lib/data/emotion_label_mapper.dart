import 'package:sentiment/models/entry.dart';

class EmotionLabelMapper {
  static const neutralLabel = 'neutral';

  static const Map<String, String?> _modelToPrimary = {
    'sadness': 'sad',
    'anger': 'angry',
    'love': 'happy',
    'surprise': 'surprised',
    'fear': 'fearful',
    'happiness': 'happy',
    'neutral': null,
    'disgust': 'disgusted',
    'shame': 'sad',
    'guilt': 'sad',
    'sarcasm': 'disgusted',
    'excitement': 'happy',
    'anxiety': 'fearful',
    'confusion': 'surprised',
    'desire': 'happy',
  };

  String? mapPrimaryId(String modelLabel) {
    return _modelToPrimary[_normalizeLabel(modelLabel)];
  }

  bool isCountable(SentenceEmotionAnnotation annotation) {
    return !_isNeutral(annotation.modelLabel);
  }

  bool _isNeutral(String label) {
    return _normalizeLabel(label) == neutralLabel;
  }

  String _normalizeLabel(String modelLabel) {
    return modelLabel.trim().toLowerCase();
  }
}
