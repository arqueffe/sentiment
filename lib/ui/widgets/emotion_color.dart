import 'package:flutter/material.dart';

Color emotionColor(BuildContext context, String primaryId) {
  const map = <String, Color>{
    'joy': Color(0xFFF4B400),
    'trust': Color(0xFF16A34A),
    'fear': Color(0xFF7C3AED),
    'surprise': Color(0xFFF97316),
    'sadness': Color(0xFF2563EB),
    'disgust': Color(0xFF65A30D),
    'anger': Color(0xFFDC2626),
    'anticipation': Color(0xFF0891B2),
  };

  final fallback = Theme.of(context).colorScheme.primary;
  return map[primaryId] ?? fallback;
}
