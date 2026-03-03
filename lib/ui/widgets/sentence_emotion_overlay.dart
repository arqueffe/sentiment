import 'package:flutter/material.dart';

import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/models/entry.dart';
import 'package:sentiment/ui/widgets/emotion_color.dart';

Map<String, Color> emotionColorById(
  BuildContext context,
  List<SentenceEmotionAnnotation> annotations,
) {
  final colorByEmotionId = <String, Color>{};
  for (final annotation in annotations) {
    final emotionId = annotation.primaryEmotionId;
    if (emotionId == null || colorByEmotionId.containsKey(emotionId)) {
      continue;
    }
    colorByEmotionId[emotionId] = emotionColor(context, emotionId);
  }
  return colorByEmotionId;
}

class SentenceEmotionOverlayText extends StatelessWidget {
  const SentenceEmotionOverlayText({
    super.key,
    required this.text,
    required this.annotations,
    this.textStyle,
    this.strutStyle,
    this.textHeightBehavior = const TextHeightBehavior(
      applyHeightToFirstAscent: true,
      applyHeightToLastDescent: true,
    ),
    this.contentPadding = EdgeInsets.zero,
    this.badgeVerticalOffset = 0,
  });

  final String text;
  final List<SentenceEmotionAnnotation> annotations;
  final TextStyle? textStyle;
  final StrutStyle? strutStyle;
  final TextHeightBehavior textHeightBehavior;
  final EdgeInsets contentPadding;
  final double badgeVerticalOffset;

  @override
  Widget build(BuildContext context) {
    final resolvedTextStyle =
        textStyle ?? Theme.of(context).textTheme.bodyLarge;
    final resolvedTextScaler = MediaQuery.textScalerOf(context);
    final colorByEmotionId = emotionColorById(context, annotations);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Padding(
              padding: contentPadding,
              child: Text(
                text,
                style: resolvedTextStyle,
                strutStyle: strutStyle,
                textScaler: resolvedTextScaler,
                textHeightBehavior: textHeightBehavior,
                textWidthBasis: TextWidthBasis.parent,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SentenceEmotionOverlayPainter(
                    text: text,
                    annotations: annotations,
                    textStyle: resolvedTextStyle ?? const TextStyle(),
                    textDirection: Directionality.of(context),
                    colorByEmotionId: colorByEmotionId,
                    fallbackColor: Theme.of(context).colorScheme.primary,
                    maxWidth: constraints.maxWidth,
                    contentPadding: contentPadding,
                    scrollOffset: 0,
                    strutStyle: strutStyle,
                    badgeVerticalOffset: badgeVerticalOffset,
                    textScaler: resolvedTextScaler,
                    textHeightBehavior: textHeightBehavior,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SentenceEmotionOverlayPainter extends CustomPainter {
  SentenceEmotionOverlayPainter({
    required this.text,
    required this.annotations,
    required this.textStyle,
    required this.textDirection,
    required this.colorByEmotionId,
    required this.fallbackColor,
    required this.maxWidth,
    required this.contentPadding,
    required this.scrollOffset,
    this.strutStyle,
    this.badgeVerticalOffset = 0,
    this.textScaler = TextScaler.noScaling,
    this.textHeightBehavior = const TextHeightBehavior(
      applyHeightToFirstAscent: true,
      applyHeightToLastDescent: true,
    ),
  });

  final String text;
  final List<SentenceEmotionAnnotation> annotations;
  final TextStyle textStyle;
  final TextDirection textDirection;
  final Map<String, Color> colorByEmotionId;
  final Color fallbackColor;
  final double maxWidth;
  final EdgeInsets contentPadding;
  final double scrollOffset;
  final StrutStyle? strutStyle;
  final double badgeVerticalOffset;
  final TextScaler textScaler;
  final TextHeightBehavior textHeightBehavior;

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty || annotations.isEmpty) {
      return;
    }

    final innerWidth = maxWidth - contentPadding.left - contentPadding.right;
    if (innerWidth <= 0) {
      return;
    }

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: textDirection,
      textAlign: TextAlign.start,
      strutStyle: strutStyle,
      textScaler: textScaler,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: TextWidthBasis.parent,
    )..layout(maxWidth: innerWidth);

    final mergedRanges = _mergedEmotionRanges();
    final labelStyle = textStyle.copyWith(
      fontSize: (textStyle.fontSize ?? 16) * 0.58,
      fontWeight: FontWeight.w600,
      height: 1,
    );

    for (final range in mergedRanges) {
      final emotionId = range.emotionId;
      final boxes = textPainter.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );
      if (boxes.isEmpty) {
        continue;
      }

      final color = colorByEmotionId[emotionId] ?? fallbackColor;
      final label = EmotionCatalog.byId(emotionId)?.label ?? emotionId;
      final textSpan = TextSpan(
        text: label,
        style: labelStyle.copyWith(color: color),
      );
      final labelPainter = TextPainter(
        text: textSpan,
        textDirection: textDirection,
        textScaler: textScaler,
        textHeightBehavior: textHeightBehavior,
      )..layout();

      const horizontalPadding = 4.0;
      const verticalPadding = 2.0;
      final badgeWidth = labelPainter.width + horizontalPadding * 2;
      final badgeHeight = labelPainter.height + verticalPadding * 2;

      final fillPaint = Paint()..color = color.withValues(alpha: 0.14);
      final strokePaint = Paint()
        ..color = color.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      for (final box in boxes) {
        final centerX = (box.left + box.right) / 2;
        var badgeLeft = contentPadding.left + centerX - (badgeWidth / 2);
        var badgeTop =
            contentPadding.top +
            box.bottom -
            (badgeHeight / 2) -
            scrollOffset +
            badgeVerticalOffset;
        final visibleTop = contentPadding.top;
        final visibleBottom = size.height - contentPadding.bottom;

        final minLeft = contentPadding.left;
        final maxLeft = size.width - contentPadding.right - badgeWidth;
        if (badgeLeft < minLeft) {
          badgeLeft = minLeft;
        } else if (badgeLeft > maxLeft) {
          badgeLeft = maxLeft;
        }
        if (badgeTop + badgeHeight < visibleTop || badgeTop > visibleBottom) {
          continue;
        }

        if (badgeTop < visibleTop) {
          badgeTop = visibleTop;
        }
        final maxTop = visibleBottom - badgeHeight;
        if (badgeTop > maxTop) {
          badgeTop = maxTop;
        }

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight),
          const Radius.circular(4),
        );

        canvas.drawRRect(rect, fillPaint);
        canvas.drawRRect(rect, strokePaint);
        labelPainter.paint(
          canvas,
          Offset(badgeLeft + horizontalPadding, badgeTop + verticalPadding),
        );
      }
    }
  }

  List<_MergedEmotionRange> _mergedEmotionRanges() {
    final sorted = [...annotations]..sort((a, b) => a.start.compareTo(b.start));
    final merged = <_MergedEmotionRange>[];

    for (final annotation in sorted) {
      final emotionId = annotation.primaryEmotionId;
      if (emotionId == null) {
        continue;
      }

      final start = annotation.start;
      final end = annotation.end;
      if (start < 0 || end > text.length || start >= end) {
        continue;
      }
      final currentSlice = text.substring(start, end).trim();
      if (currentSlice != annotation.sentence.trim()) {
        continue;
      }

      if (merged.isEmpty) {
        merged.add(
          _MergedEmotionRange(start: start, end: end, emotionId: emotionId),
        );
        continue;
      }

      final last = merged.last;
      final isSameEmotion = last.emotionId == emotionId;
      final overlaps = start <= last.end;
      final gap = start > last.end ? text.substring(last.end, start) : '';
      final whitespaceOnlyGap =
          gap.trim().isEmpty && !gap.contains(RegExp(r'[\r\n]'));

      if (isSameEmotion && (overlaps || whitespaceOnlyGap)) {
        merged[merged.length - 1] = _MergedEmotionRange(
          start: last.start,
          end: end > last.end ? end : last.end,
          emotionId: emotionId,
        );
        continue;
      }

      merged.add(
        _MergedEmotionRange(start: start, end: end, emotionId: emotionId),
      );
    }

    return merged;
  }

  @override
  bool shouldRepaint(covariant SentenceEmotionOverlayPainter oldDelegate) {
    if (oldDelegate.text != text ||
        oldDelegate.maxWidth != maxWidth ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.fallbackColor != fallbackColor ||
        oldDelegate.contentPadding != contentPadding ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.strutStyle != strutStyle ||
        oldDelegate.badgeVerticalOffset != badgeVerticalOffset ||
        oldDelegate.textScaler != textScaler ||
        oldDelegate.textHeightBehavior != textHeightBehavior ||
        oldDelegate.annotations.length != annotations.length) {
      return true;
    }
    if (oldDelegate.colorByEmotionId.length != colorByEmotionId.length) {
      return true;
    }
    for (final entry in colorByEmotionId.entries) {
      if (oldDelegate.colorByEmotionId[entry.key] != entry.value) {
        return true;
      }
    }
    for (var i = 0; i < annotations.length; i++) {
      final current = annotations[i];
      final previous = oldDelegate.annotations[i];
      if (current.start != previous.start ||
          current.end != previous.end ||
          current.primaryEmotionId != previous.primaryEmotionId ||
          current.modelLabel != previous.modelLabel) {
        return true;
      }
    }
    return false;
  }
}

class _MergedEmotionRange {
  const _MergedEmotionRange({
    required this.start,
    required this.end,
    required this.emotionId,
  });

  final int start;
  final int end;
  final String emotionId;
}
