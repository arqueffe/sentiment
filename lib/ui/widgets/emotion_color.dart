import 'package:flutter/material.dart';
import 'package:sentiment/models/emotion.dart';

Color emotionColor(BuildContext context, String primaryId) {
  const map = <String, Color>{
    'sad': Color(0xFF2563EB),
    'happy': Color(0xFFF4B400),
    'disgusted': Color(0xFF65A30D),
    'angry': Color(0xFFDC2626),
    'fearful': Color(0xFF7C3AED),
    'bad': Color(0xFF0891B2),
    'surprised': Color(0xFFF97316),
  };

  final fallback = Theme.of(context).colorScheme.primary;
  final normalizedId = EmotionCatalog.normalizeId(primaryId);
  return map[normalizedId] ?? fallback;
}
