import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sentiment/models/emotion.dart';
import 'package:sentiment/ui/widgets/emotion_color.dart';

Future<EmotionSelection?> showEmotionPicker(BuildContext context) {
  return showModalBottomSheet<EmotionSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const EmotionPickerSheet(),
  );
}

class EmotionPickerSheet extends StatefulWidget {
  const EmotionPickerSheet({super.key});

  @override
  State<EmotionPickerSheet> createState() => _EmotionPickerSheetState();
}

class _EmotionPickerSheetState extends State<EmotionPickerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  EmotionNode? _primary;
  EmotionNode? _secondary;
  String? _hoverPrimaryId;
  String? _hoverSecondaryId;
  String? _hoverTertiaryId;

  List<EmotionNode> get _primaryNodes => EmotionCatalog.wheel;

  List<EmotionNode> get _secondaryNodes {
    if (_primary == null) {
      return const [];
    }
    return _primary!.children;
  }

  List<EmotionNode> get _tertiaryNodes {
    if (_secondary == null) {
      return const [];
    }
    return _secondary!.children;
  }

  String get _title {
    if (_primary == null) {
      return 'Pick a primary emotion';
    }
    if (_secondary == null) {
      return 'Refine with a secondary emotion';
    }
    return 'Pick a detailed emotion';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      upperBound: 2,
      value: 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setDepthAnimation() {
    final target = _secondary != null
        ? 2.0
        : _primary != null
        ? 1.0
        : 0.0;
    _controller.animateTo(target, curve: Curves.easeOutCubic);
  }

  void _onTap(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final radius = size.shortestSide / 2;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance <= radius * 0.22) {
      _goBack();
      return;
    }
    if (distance > radius) {
      return;
    }

    final angle = (math.atan2(dy, dx) + 2 * math.pi) % (2 * math.pi);
    final normalized = distance / radius;

    if (normalized >= 0.22 && normalized < 0.50) {
      final selected = _pickByAngle(_primaryNodes, angle);
      if (selected == null) {
        return;
      }
      setState(() {
        _primary = selected;
        _secondary = null;
      });
      _setDepthAnimation();
      return;
    }

    if (normalized >= 0.50 && normalized < 0.76 && _primary != null) {
      final selected = _pickByAngle(_secondaryNodes, angle);
      if (selected == null) {
        return;
      }
      setState(() {
        _secondary = selected;
      });
      _setDepthAnimation();
      return;
    }

    if (normalized >= 0.76 &&
        normalized <= 1.0 &&
        _primary != null &&
        _secondary != null) {
      final selected = _pickByAngle(_tertiaryNodes, angle);
      if (selected == null) {
        return;
      }
      Navigator.of(context).pop(
        EmotionSelection(primaryId: _primary!.id, secondaryId: selected.id),
      );
    }
  }

  EmotionNode? _pickByAngle(List<EmotionNode> nodes, double angle) {
    if (nodes.isEmpty) {
      return null;
    }
    final sweep = (2 * math.pi) / nodes.length;
    final adjustedAngle = (angle + math.pi / 2) % (2 * math.pi);
    final index = (adjustedAngle / sweep).floor().clamp(0, nodes.length - 1);
    return nodes[index];
  }

  void _onHover(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final radius = size.shortestSide / 2;
    final distance = math.sqrt(dx * dx + dy * dy);
    final angle = (math.atan2(dy, dx) + 2 * math.pi) % (2 * math.pi);
    final normalized = distance / radius;

    String? nextPrimary;
    String? nextSecondary;
    String? nextTertiary;

    if (normalized >= 0.22 && normalized < 0.50) {
      nextPrimary = _pickByAngle(_primaryNodes, angle)?.id;
    } else if (normalized >= 0.50 && normalized < 0.76 && _primary != null) {
      nextSecondary = _pickByAngle(_secondaryNodes, angle)?.id;
    } else if (normalized >= 0.76 &&
        normalized <= 1.0 &&
        _primary != null &&
        _secondary != null) {
      nextTertiary = _pickByAngle(_tertiaryNodes, angle)?.id;
    }

    if (_hoverPrimaryId == nextPrimary &&
        _hoverSecondaryId == nextSecondary &&
        _hoverTertiaryId == nextTertiary) {
      return;
    }

    setState(() {
      _hoverPrimaryId = nextPrimary;
      _hoverSecondaryId = nextSecondary;
      _hoverTertiaryId = nextTertiary;
    });
  }

  void _clearHover() {
    if (_hoverPrimaryId == null &&
        _hoverSecondaryId == null &&
        _hoverTertiaryId == null) {
      return;
    }
    setState(() {
      _hoverPrimaryId = null;
      _hoverSecondaryId = null;
      _hoverTertiaryId = null;
    });
  }

  void _useCurrentLevel() {
    if (_primary == null) {
      return;
    }
    if (_secondary == null) {
      Navigator.of(context).pop(EmotionSelection(primaryId: _primary!.id));
      return;
    }
    Navigator.of(context).pop(
      EmotionSelection(primaryId: _primary!.id, secondaryId: _secondary!.id),
    );
  }

  void _goBack() {
    setState(() {
      if (_secondary != null) {
        _secondary = null;
      } else {
        _primary = null;
      }
    });
    _setDepthAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final wheelSize = math.min(MediaQuery.of(context).size.width - 48, 420.0);

    final pathLabels = [
      if (_primary != null) _primary!.label,
      if (_secondary != null) _secondary!.label,
    ];

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SizedBox(
            height: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: pathLabels.isEmpty
                        ? Text(
                            'Tap the wheel rings from center outward.',
                            key: const ValueKey('hint'),
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : Wrap(
                            key: ValueKey(pathLabels.join('|')),
                            spacing: 8,
                            runSpacing: 8,
                            children: pathLabels
                                .map(
                                  (label) => Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(label),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: wheelSize,
                      height: wheelSize,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final depth = _controller.value;
                          final primaryOpacity = depth < 1
                              ? (1 - 0.65 * depth).clamp(0.0, 1.0)
                              : 0.32;
                          final secondaryOpacity = Curves.easeOut.transform(
                            depth < 1
                                ? 0
                                : depth < 2
                                ? (0.35 + 0.65 * (depth - 1)).clamp(0.0, 1.0)
                                : 0.32,
                          );
                          final tertiaryOpacity = Curves.easeOut.transform(
                            (depth - 1).clamp(0.0, 1.0),
                          );

                          return MouseRegion(
                            onHover: (event) => _onHover(
                              event.localPosition,
                              Size.square(wheelSize),
                            ),
                            onExit: (_) => _clearHover(),
                            child: GestureDetector(
                              onTapUp: (details) {
                                _onTap(
                                  details.localPosition,
                                  Size.square(wheelSize),
                                );
                              },
                              child: CustomPaint(
                                painter: _EmotionWheelPainter(
                                  context: context,
                                  primaryNodes: _primaryNodes,
                                  secondaryNodes: _secondaryNodes,
                                  tertiaryNodes: _tertiaryNodes,
                                  selectedPrimaryId: _primary?.id,
                                  selectedSecondaryId: _secondary?.id,
                                  hoveredPrimaryId: _hoverPrimaryId,
                                  hoveredSecondaryId: _hoverSecondaryId,
                                  hoveredTertiaryId: _hoverTertiaryId,
                                  primaryOpacity: primaryOpacity,
                                  secondaryOpacity: secondaryOpacity,
                                  tertiaryOpacity: tertiaryOpacity,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _RingLegend(primary: _primary, secondary: _secondary),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: (_primary == null && _secondary == null)
                          ? null
                          : _goBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _useCurrentLevel,
                      child: Text(
                        _secondary == null
                            ? (_primary == null
                                  ? 'Skip mood detail'
                                  : 'Use ${_primary!.label}')
                            : 'Use ${_secondary!.label}',
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Skip mood'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingLegend extends StatelessWidget {
  const _RingLegend({required this.primary, required this.secondary});

  final EmotionNode? primary;
  final EmotionNode? secondary;

  @override
  Widget build(BuildContext context) {
    return Text(
      primary == null
          ? 'Selection: none'
          : secondary == null
          ? 'Selection: ${primary!.label}'
          : 'Selection: ${primary!.label} · ${secondary!.label}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _EmotionWheelPainter extends CustomPainter {
  _EmotionWheelPainter({
    required this.context,
    required this.primaryNodes,
    required this.secondaryNodes,
    required this.tertiaryNodes,
    required this.selectedPrimaryId,
    required this.selectedSecondaryId,
    required this.hoveredPrimaryId,
    required this.hoveredSecondaryId,
    required this.hoveredTertiaryId,
    required this.primaryOpacity,
    required this.secondaryOpacity,
    required this.tertiaryOpacity,
  });

  final BuildContext context;
  final List<EmotionNode> primaryNodes;
  final List<EmotionNode> secondaryNodes;
  final List<EmotionNode> tertiaryNodes;
  final String? selectedPrimaryId;
  final String? selectedSecondaryId;
  final String? hoveredPrimaryId;
  final String? hoveredSecondaryId;
  final String? hoveredTertiaryId;
  final double primaryOpacity;
  final double secondaryOpacity;
  final double tertiaryOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    _drawRing(
      canvas: canvas,
      center: center,
      radius: radius,
      innerFactor: 0.22,
      outerFactor: 0.50,
      nodes: primaryNodes,
      colorFor: (node, _) => emotionColor(context, node.id),
      selectedId: selectedPrimaryId,
      hoveredId: hoveredPrimaryId,
      opacity: primaryOpacity,
      muted: selectedSecondaryId != null,
      drawLabels: true,
    );

    _drawRing(
      canvas: canvas,
      center: center,
      radius: radius,
      innerFactor: 0.50,
      outerFactor: 0.76,
      nodes: secondaryNodes,
      colorFor: (node, _) {
        final base = emotionColor(context, selectedPrimaryId ?? node.id);
        final hsl = HSLColor.fromColor(base);
        return hsl
            .withLightness((hsl.lightness + 0.16).clamp(0.0, 1.0))
            .toColor();
      },
      selectedId: selectedSecondaryId,
      hoveredId: hoveredSecondaryId,
      opacity: secondaryOpacity,
      muted: selectedSecondaryId != null,
      drawLabels: true,
    );

    _drawRing(
      canvas: canvas,
      center: center,
      radius: radius,
      innerFactor: 0.76,
      outerFactor: 1,
      nodes: tertiaryNodes,
      colorFor: (node, _) {
        final base = emotionColor(context, selectedPrimaryId ?? node.id);
        final hsl = HSLColor.fromColor(base);
        return hsl
            .withLightness((hsl.lightness + 0.26).clamp(0.0, 1.0))
            .toColor();
      },
      selectedId: null,
      hoveredId: hoveredTertiaryId,
      opacity: tertiaryOpacity,
      muted: false,
      drawLabels: true,
    );
  }

  void _drawRing({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double innerFactor,
    required double outerFactor,
    required List<EmotionNode> nodes,
    required Color Function(EmotionNode node, int index) colorFor,
    required String? selectedId,
    required String? hoveredId,
    required double opacity,
    required bool muted,
    required bool drawLabels,
  }) {
    if (nodes.isEmpty || opacity <= 0.001) {
      return;
    }

    final inner = radius * innerFactor;
    final outer = radius * outerFactor;
    final sweep = (2 * math.pi) / nodes.length;
    final ringRect = Rect.fromCircle(
      center: center,
      radius: (inner + outer) / 2,
    );
    final strokeWidth = outer - inner;

    for (var index = 0; index < nodes.length; index += 1) {
      final node = nodes[index];
      final baseColor = colorFor(node, index);
      final mutedBlend = Color.alphaBlend(
        Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.60),
        baseColor,
      );
      final color = (muted ? mutedBlend : baseColor).withValues(alpha: opacity);
      final isSelected = node.id == selectedId;
      final isHovered = node.id == hoveredId;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? strokeWidth + 3 : strokeWidth
        ..color = (isSelected || isHovered)
            ? color
            : color.withValues(alpha: 0.82)
        ..maskFilter = (isSelected || isHovered)
            ? const MaskFilter.blur(BlurStyle.normal, 2)
            : null;

      final start = -math.pi / 2 + index * sweep;
      canvas.drawArc(ringRect, start, sweep, false, paint);

      if (drawLabels) {
        final mid = start + sweep / 2;
        final labelRadius = (inner + outer) / 2;
        final labelOffset = Offset(
          center.dx + labelRadius * math.cos(mid),
          center.dy + labelRadius * math.sin(mid),
        );

        final text = node.label;
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: muted
                  ? Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.82)
                  : Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: strokeWidth * 1.5);

        canvas.save();
        canvas.translate(labelOffset.dx, labelOffset.dy);
        canvas.rotate(mid + math.pi / 2);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EmotionWheelPainter oldDelegate) {
    return selectedPrimaryId != oldDelegate.selectedPrimaryId ||
        selectedSecondaryId != oldDelegate.selectedSecondaryId ||
        hoveredPrimaryId != oldDelegate.hoveredPrimaryId ||
        hoveredSecondaryId != oldDelegate.hoveredSecondaryId ||
        hoveredTertiaryId != oldDelegate.hoveredTertiaryId ||
        primaryOpacity != oldDelegate.primaryOpacity ||
        secondaryOpacity != oldDelegate.secondaryOpacity ||
        tertiaryOpacity != oldDelegate.tertiaryOpacity ||
        primaryNodes.length != oldDelegate.primaryNodes.length ||
        secondaryNodes.length != oldDelegate.secondaryNodes.length ||
        tertiaryNodes.length != oldDelegate.tertiaryNodes.length;
  }
}
