class EmotionNode {
  const EmotionNode({
    required this.id,
    required this.label,
    this.children = const [],
  });

  final String id;
  final String label;
  final List<EmotionNode> children;
}

class EmotionSelection {
  const EmotionSelection({required this.primaryId, this.secondaryId});

  final String primaryId;
  final String? secondaryId;

  String get label {
    final labels = EmotionCatalog.pathLabels(
      primaryId: primaryId,
      selectedId: secondaryId,
    );
    if (labels.isEmpty) {
      return primaryId;
    }
    return labels.join(' · ');
  }
}

class EmotionCatalog {
  static const List<EmotionNode> wheel = [
    EmotionNode(
      id: 'joy',
      label: 'Joy',
      children: [
        EmotionNode(
          id: 'joy_cheerful',
          label: 'Cheerful',
          children: [
            EmotionNode(id: 'joy_cheerful_optimistic', label: 'Optimistic'),
            EmotionNode(id: 'joy_cheerful_energetic', label: 'Energetic'),
            EmotionNode(id: 'joy_cheerful_playful', label: 'Playful'),
          ],
        ),
        EmotionNode(
          id: 'joy_proud',
          label: 'Proud',
          children: [
            EmotionNode(id: 'joy_proud_accomplished', label: 'Accomplished'),
            EmotionNode(id: 'joy_proud_confident', label: 'Confident'),
            EmotionNode(id: 'joy_proud_validated', label: 'Validated'),
          ],
        ),
        EmotionNode(
          id: 'joy_peaceful',
          label: 'Peaceful',
          children: [
            EmotionNode(id: 'joy_peaceful_relieved', label: 'Relieved'),
            EmotionNode(id: 'joy_peaceful_content', label: 'Content'),
            EmotionNode(id: 'joy_peaceful_grateful', label: 'Grateful'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'trust',
      label: 'Trust',
      children: [
        EmotionNode(
          id: 'trust_connected',
          label: 'Connected',
          children: [
            EmotionNode(id: 'trust_connected_loved', label: 'Loved'),
            EmotionNode(id: 'trust_connected_supported', label: 'Supported'),
            EmotionNode(id: 'trust_connected_seen', label: 'Seen'),
          ],
        ),
        EmotionNode(
          id: 'trust_safe',
          label: 'Safe',
          children: [
            EmotionNode(id: 'trust_safe_secure', label: 'Secure'),
            EmotionNode(id: 'trust_safe_grounded', label: 'Grounded'),
            EmotionNode(id: 'trust_safe_accepted', label: 'Accepted'),
          ],
        ),
        EmotionNode(
          id: 'trust_admiring',
          label: 'Admiring',
          children: [
            EmotionNode(id: 'trust_admiring_inspired', label: 'Inspired'),
            EmotionNode(id: 'trust_admiring_respectful', label: 'Respectful'),
            EmotionNode(id: 'trust_admiring_reassured', label: 'Reassured'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'fear',
      label: 'Fear',
      children: [
        EmotionNode(
          id: 'fear_anxious',
          label: 'Anxious',
          children: [
            EmotionNode(id: 'fear_anxious_overwhelmed', label: 'Overwhelmed'),
            EmotionNode(id: 'fear_anxious_uneasy', label: 'Uneasy'),
            EmotionNode(id: 'fear_anxious_tense', label: 'Tense'),
          ],
        ),
        EmotionNode(
          id: 'fear_insecure',
          label: 'Insecure',
          children: [
            EmotionNode(id: 'fear_insecure_exposed', label: 'Exposed'),
            EmotionNode(id: 'fear_insecure_uncertain', label: 'Uncertain'),
            EmotionNode(id: 'fear_insecure_small', label: 'Small'),
          ],
        ),
        EmotionNode(
          id: 'fear_worried',
          label: 'Worried',
          children: [
            EmotionNode(id: 'fear_worried_restless', label: 'Restless'),
            EmotionNode(id: 'fear_worried_doubtful', label: 'Doubtful'),
            EmotionNode(id: 'fear_worried_stressed', label: 'Stressed'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'surprise',
      label: 'Surprise',
      children: [
        EmotionNode(
          id: 'surprise_amazed',
          label: 'Amazed',
          children: [
            EmotionNode(id: 'surprise_amazed_awe', label: 'Awe'),
            EmotionNode(id: 'surprise_amazed_impressed', label: 'Impressed'),
            EmotionNode(id: 'surprise_amazed_delighted', label: 'Delighted'),
          ],
        ),
        EmotionNode(
          id: 'surprise_confused',
          label: 'Confused',
          children: [
            EmotionNode(
              id: 'surprise_confused_disoriented',
              label: 'Disoriented',
            ),
            EmotionNode(id: 'surprise_confused_unsure', label: 'Unsure'),
            EmotionNode(id: 'surprise_confused_perplexed', label: 'Perplexed'),
          ],
        ),
        EmotionNode(
          id: 'surprise_shocked',
          label: 'Shocked',
          children: [
            EmotionNode(id: 'surprise_shocked_stunned', label: 'Stunned'),
            EmotionNode(id: 'surprise_shocked_startled', label: 'Startled'),
            EmotionNode(id: 'surprise_shocked_disbelief', label: 'Disbelief'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'sadness',
      label: 'Sadness',
      children: [
        EmotionNode(
          id: 'sadness_hurt',
          label: 'Hurt',
          children: [
            EmotionNode(id: 'sadness_hurt_broken', label: 'Broken'),
            EmotionNode(id: 'sadness_hurt_rejected', label: 'Rejected'),
            EmotionNode(id: 'sadness_hurt_sensitive', label: 'Sensitive'),
          ],
        ),
        EmotionNode(
          id: 'sadness_lonely',
          label: 'Lonely',
          children: [
            EmotionNode(id: 'sadness_lonely_isolated', label: 'Isolated'),
            EmotionNode(id: 'sadness_lonely_empty', label: 'Empty'),
            EmotionNode(id: 'sadness_lonely_unseen', label: 'Unseen'),
          ],
        ),
        EmotionNode(
          id: 'sadness_disappointed',
          label: 'Disappointed',
          children: [
            EmotionNode(id: 'sadness_disappointed_down', label: 'Let Down'),
            EmotionNode(
              id: 'sadness_disappointed_regretful',
              label: 'Regretful',
            ),
            EmotionNode(
              id: 'sadness_disappointed_discouraged',
              label: 'Discouraged',
            ),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'disgust',
      label: 'Disgust',
      children: [
        EmotionNode(
          id: 'disgust_distaste',
          label: 'Distaste',
          children: [
            EmotionNode(id: 'disgust_distaste_putoff', label: 'Put Off'),
            EmotionNode(id: 'disgust_distaste_repelled', label: 'Repelled'),
            EmotionNode(id: 'disgust_distaste_averse', label: 'Averse'),
          ],
        ),
        EmotionNode(
          id: 'disgust_dislike',
          label: 'Dislike',
          children: [
            EmotionNode(id: 'disgust_dislike_irked', label: 'Irked'),
            EmotionNode(id: 'disgust_dislike_annoyed', label: 'Annoyed'),
            EmotionNode(id: 'disgust_dislike_resistant', label: 'Resistant'),
          ],
        ),
        EmotionNode(
          id: 'disgust_ashamed',
          label: 'Ashamed',
          children: [
            EmotionNode(id: 'disgust_ashamed_guilty', label: 'Guilty'),
            EmotionNode(
              id: 'disgust_ashamed_embarrassed',
              label: 'Embarrassed',
            ),
            EmotionNode(id: 'disgust_ashamed_remorseful', label: 'Remorseful'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'anger',
      label: 'Anger',
      children: [
        EmotionNode(
          id: 'anger_irritated',
          label: 'Irritated',
          children: [
            EmotionNode(id: 'anger_irritated_impatient', label: 'Impatient'),
            EmotionNode(id: 'anger_irritated_agitated', label: 'Agitated'),
            EmotionNode(id: 'anger_irritated_snappy', label: 'Snappy'),
          ],
        ),
        EmotionNode(
          id: 'anger_frustrated',
          label: 'Frustrated',
          children: [
            EmotionNode(id: 'anger_frustrated_stuck', label: 'Stuck'),
            EmotionNode(id: 'anger_frustrated_blocked', label: 'Blocked'),
            EmotionNode(id: 'anger_frustrated_powerless', label: 'Powerless'),
          ],
        ),
        EmotionNode(
          id: 'anger_hurt',
          label: 'Hurt / Betrayed',
          children: [
            EmotionNode(id: 'anger_hurt_betrayed', label: 'Betrayed'),
            EmotionNode(id: 'anger_hurt_unfair', label: 'Treated Unfairly'),
            EmotionNode(id: 'anger_hurt_resentful', label: 'Resentful'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'anticipation',
      label: 'Anticipation',
      children: [
        EmotionNode(
          id: 'anticipation_hopeful',
          label: 'Hopeful',
          children: [
            EmotionNode(
              id: 'anticipation_hopeful_encouraged',
              label: 'Encouraged',
            ),
            EmotionNode(
              id: 'anticipation_hopeful_motivated',
              label: 'Motivated',
            ),
            EmotionNode(id: 'anticipation_hopeful_focused', label: 'Focused'),
          ],
        ),
        EmotionNode(
          id: 'anticipation_eager',
          label: 'Eager',
          children: [
            EmotionNode(id: 'anticipation_eager_excited', label: 'Excited'),
            EmotionNode(id: 'anticipation_eager_ready', label: 'Ready'),
            EmotionNode(id: 'anticipation_eager_curious', label: 'Curious'),
          ],
        ),
        EmotionNode(
          id: 'anticipation_restless',
          label: 'Restless',
          children: [
            EmotionNode(
              id: 'anticipation_restless_impatient',
              label: 'Impatient',
            ),
            EmotionNode(id: 'anticipation_restless_antsy', label: 'Antsy'),
            EmotionNode(id: 'anticipation_restless_onedge', label: 'On Edge'),
          ],
        ),
      ],
    ),
  ];

  static final Map<String, EmotionNode> _byId = {
    for (final node in _flatten(wheel)) node.id: node,
  };

  static final Map<String, String?> _parentById = {
    for (final root in wheel) root.id: null,
    ..._buildParentMap(wheel),
  };

  static const Map<String, String> _legacyAliases = {
    'joy_pride': 'joy_proud',
    'joy_gratitude': 'joy_peaceful_grateful',
    'joy_relief': 'joy_peaceful_relieved',
    'trust_admiration': 'trust_admiring',
    'trust_safety': 'trust_safe',
    'trust_acceptance': 'trust_safe_accepted',
    'fear_anxiety': 'fear_anxious',
    'fear_insecurity': 'fear_insecure',
    'fear_worry': 'fear_worried',
    'surprise_awe': 'surprise_amazed_awe',
    'surprise_confusion': 'surprise_confused',
    'surprise_shock': 'surprise_shocked',
    'sadness_grief': 'sadness_hurt_broken',
    'disgust_uneasy': 'fear_anxious_uneasy',
    'anger_betrayed': 'anger_hurt_betrayed',
    'anticipation_hope': 'anticipation_hopeful',
  };

  static String normalizeId(String id) => _legacyAliases[id] ?? id;

  static EmotionNode? byId(String id) => _byId[normalizeId(id)];

  static List<String> pathLabels({
    required String primaryId,
    String? selectedId,
  }) {
    final normalizedPrimaryId = normalizeId(primaryId);
    final normalizedSelectedId = selectedId == null
        ? null
        : normalizeId(selectedId);

    final primary = byId(normalizedPrimaryId);
    if (primary == null) {
      return [normalizedPrimaryId];
    }
    if (normalizedSelectedId == null ||
        normalizedSelectedId == normalizedPrimaryId) {
      return [primary.label];
    }

    final selected = byId(normalizedSelectedId);
    if (selected == null) {
      return [primary.label, normalizedSelectedId];
    }

    final path = <EmotionNode>[];
    String? cursor = selected.id;
    while (cursor != null) {
      final node = byId(cursor);
      if (node == null) {
        break;
      }
      path.add(node);
      if (cursor == normalizedPrimaryId) {
        return path.reversed.map((node) => node.label).toList();
      }
      cursor = _parentById[cursor];
    }
    return [primary.label, selected.label];
  }

  static List<EmotionNode> _flatten(List<EmotionNode> roots) {
    final all = <EmotionNode>[];
    for (final node in roots) {
      all.add(node);
      if (node.children.isNotEmpty) {
        all.addAll(_flatten(node.children));
      }
    }
    return all;
  }

  static Map<String, String?> _buildParentMap(List<EmotionNode> roots) {
    final map = <String, String?>{};
    for (final node in roots) {
      for (final child in node.children) {
        map[child.id] = node.id;
      }
      map.addAll(_buildParentMap(node.children));
    }
    return map;
  }
}
