import 'package:sentiment/models/entry.dart';
import 'package:sentiment/models/emotion.dart';

class EmotionLabelMapper {
  static const neutralLabel = 'neutral';

  static const Map<String, String?> _modelToDetected = {
    'sadness': 'sad',
    'anger': 'angry',
    'love': 'happy_peaceful_loving',
    'surprise': 'surprised',
    'fear': 'fearful',
    'happiness': 'happy',
    'neutral': null,
    'disgust': 'disgusted',
    'shame': 'sad_guilty_ashamed',
    'guilt': 'sad_guilty',
    'sarcasm': 'angry_critical_dismissive',
    'excitement': 'surprised_excited',
    'anxiety': 'fearful_anxious',
    'confusion': 'surprised_confused',
    'desire': 'happy_interested',
  };

  String? mapDetectedId(String modelLabel) {
    final detectedId = _modelToDetected[_normalizeLabel(modelLabel)];
    if (detectedId == null) {
      return null;
    }
    return EmotionCatalog.byId(detectedId)?.id;
  }

  String? mapPrimaryId(String modelLabel) {
    final detectedId = mapDetectedId(modelLabel);
    if (detectedId == null) {
      return null;
    }
    return EmotionCatalog.primaryIdFor(detectedId);
  }

  bool isCountable(SentenceEmotionAnnotation annotation) {
    return mapDetectedId(annotation.modelLabel) != null;
  }

  String _normalizeLabel(String modelLabel) {
    return modelLabel.trim().toLowerCase();
  }
}
