import 'package:sentiment/models/entry.dart';

class EmotionLabelMapper {
  static const neutralLabel = 'neutral';

  static const Map<String, String?> _modelToPrimary = {
    'sadness': 'sadness',
    'anger': 'anger',
    'love': 'trust',
    'surprise': 'surprise',
    'fear': 'fear',
    'happiness': 'joy',
    'neutral': null,
    'disgust': 'disgust',
    'shame': 'sadness',
    'guilt': 'sadness',
    'sarcasm': 'disgust',
    'excitement': 'anticipation',
    'anxiety': 'fear',
    'confusion': 'surprise',
    'desire': 'anticipation',
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
