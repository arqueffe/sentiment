import 'package:flutter/material.dart';

import 'package:sentiment/models/entry.dart';
import 'package:sentiment/ui/widgets/emotion_color.dart';

class AnnotatedTextController extends TextEditingController {
  List<SentenceEmotionAnnotation> _annotations = const [];
  ValueChanged<SentenceEmotionAnnotation?>? onAnnotationHover;

  bool _annotationMatchesCurrentText(SentenceEmotionAnnotation annotation) {
    if (annotation.start < 0 || annotation.end > text.length) {
      return false;
    }
    final currentSlice = text
        .substring(annotation.start, annotation.end)
        .trim();
    return currentSlice == annotation.sentence.trim();
  }

  SentenceEmotionAnnotation? annotationNearOffset(int offset) {
    if (_annotations.isEmpty || text.isEmpty) {
      return null;
    }

    final normalizedOffset = offset.clamp(0, text.length);
    final candidates = normalizedOffset > 0
        ? <int>[normalizedOffset, normalizedOffset - 1]
        : <int>[normalizedOffset];

    for (final candidate in candidates) {
      for (final annotation in _annotations) {
        if (annotation.primaryEmotionId == null) {
          continue;
        }
        if (!_annotationMatchesCurrentText(annotation)) {
          continue;
        }
        if (candidate >= annotation.start && candidate < annotation.end) {
          return annotation;
        }
      }
    }

    return null;
  }

  void setAnnotations(List<SentenceEmotionAnnotation> annotations) {
    if (_sameAnnotations(_annotations, annotations)) {
      return;
    }
    _annotations = annotations;
    notifyListeners();
  }

  bool _sameAnnotations(
    List<SentenceEmotionAnnotation> left,
    List<SentenceEmotionAnnotation> right,
  ) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i++) {
      if (left[i].start != right[i].start ||
          left[i].end != right[i].end ||
          left[i].modelLabel != right[i].modelLabel ||
          left[i].detectedEmotionId != right[i].detectedEmotionId ||
          left[i].primaryEmotionId != right[i].primaryEmotionId) {
        return false;
      }
    }
    return true;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_annotations.isEmpty || text.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final baseStyle = style ?? Theme.of(context).textTheme.bodyLarge;
    final children = <InlineSpan>[];
    var currentIndex = 0;

    final sorted = [..._annotations]
      ..sort((a, b) => a.start.compareTo(b.start));
    for (final annotation in sorted) {
      if (annotation.start < currentIndex || annotation.end > text.length) {
        continue;
      }
      if (!_annotationMatchesCurrentText(annotation)) {
        continue;
      }
      if (annotation.start > currentIndex) {
        children.add(
          TextSpan(
            text: text.substring(currentIndex, annotation.start),
            style: baseStyle,
          ),
        );
      }

      final primaryEmotionId = annotation.primaryEmotionId;
      final sentenceText = text.substring(annotation.start, annotation.end);
      final sentenceStyle = primaryEmotionId == null
          ? baseStyle
          : baseStyle?.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: emotionColor(context, primaryEmotionId),
              decorationThickness: 2,
            );
      if (primaryEmotionId == null) {
        children.add(TextSpan(text: sentenceText, style: sentenceStyle));
      } else {
        children.add(
          TextSpan(
            text: sentenceText,
            style: sentenceStyle,
            mouseCursor: SystemMouseCursors.help,
            onEnter: (_) => onAnnotationHover?.call(annotation),
            onExit: (_) => onAnnotationHover?.call(null),
          ),
        );
      }
      currentIndex = annotation.end;
    }

    if (currentIndex < text.length) {
      children.add(
        TextSpan(text: text.substring(currentIndex), style: baseStyle),
      );
    }

    return TextSpan(style: baseStyle, children: children);
  }
}
