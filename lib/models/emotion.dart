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
      id: 'sad',
      label: 'Sad',
      children: [
        EmotionNode(
          id: 'sad_lonely',
          label: 'Lonely',
          children: [
            EmotionNode(id: 'sad_lonely_isolated', label: 'Isolated'),
            EmotionNode(id: 'sad_lonely_abandoned', label: 'Abandoned'),
          ],
        ),
        EmotionNode(
          id: 'sad_vulnerable',
          label: 'Vulnerable',
          children: [
            EmotionNode(id: 'sad_vulnerable_victimized', label: 'Victimized'),
            EmotionNode(id: 'sad_vulnerable_fragile', label: 'Fragile'),
          ],
        ),
        EmotionNode(
          id: 'sad_despair',
          label: 'Despair',
          children: [
            EmotionNode(id: 'sad_despair_grief', label: 'Grief'),
            EmotionNode(id: 'sad_despair_powerless', label: 'Powerless'),
          ],
        ),
        EmotionNode(
          id: 'sad_guilty',
          label: 'Guilty',
          children: [
            EmotionNode(id: 'sad_guilty_ashamed', label: 'Ashamed'),
            EmotionNode(id: 'sad_guilty_remorseful', label: 'Remorseful'),
          ],
        ),
        EmotionNode(
          id: 'sad_depressed',
          label: 'Depressed',
          children: [
            EmotionNode(id: 'sad_depressed_empty', label: 'Empty'),
            EmotionNode(id: 'sad_depressed_inferior', label: 'Inferior'),
          ],
        ),
        EmotionNode(
          id: 'sad_hurt',
          label: 'Hurt',
          children: [
            EmotionNode(id: 'sad_hurt_disappointed', label: 'Disappointed'),
            EmotionNode(id: 'sad_hurt_embarrassed', label: 'Embarrassed'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'happy',
      label: 'Happy',
      children: [
        EmotionNode(
          id: 'happy_playful',
          label: 'Playful',
          children: [
            EmotionNode(id: 'happy_playful_aroused', label: 'Aroused'),
            EmotionNode(id: 'happy_playful_cheeky', label: 'Cheeky'),
          ],
        ),
        EmotionNode(
          id: 'happy_content',
          label: 'Content',
          children: [
            EmotionNode(id: 'happy_content_free', label: 'Free'),
            EmotionNode(id: 'happy_content_joyful', label: 'Joyful'),
          ],
        ),
        EmotionNode(
          id: 'happy_interested',
          label: 'Interested',
          children: [
            EmotionNode(id: 'happy_interested_curious', label: 'Curious'),
            EmotionNode(
              id: 'happy_interested_inquisitive',
              label: 'Inquisitive',
            ),
          ],
        ),
        EmotionNode(
          id: 'happy_proud',
          label: 'Proud',
          children: [
            EmotionNode(id: 'happy_proud_successful', label: 'Successful'),
            EmotionNode(id: 'happy_proud_confident', label: 'Confident'),
          ],
        ),
        EmotionNode(
          id: 'happy_accepting',
          label: 'Accepting',
          children: [
            EmotionNode(id: 'happy_accepting_respected', label: 'Respected'),
            EmotionNode(id: 'happy_accepting_valued', label: 'Valued'),
          ],
        ),
        EmotionNode(
          id: 'happy_powerful',
          label: 'Powerful',
          children: [
            EmotionNode(id: 'happy_powerful_courageous', label: 'Courageous'),
            EmotionNode(id: 'happy_powerful_creative', label: 'Creative'),
          ],
        ),
        EmotionNode(
          id: 'happy_peaceful',
          label: 'Peaceful',
          children: [
            EmotionNode(id: 'happy_peaceful_loving', label: 'Loving'),
            EmotionNode(id: 'happy_peaceful_thankful', label: 'Thankful'),
          ],
        ),
        EmotionNode(
          id: 'happy_trusting',
          label: 'Trusting',
          children: [
            EmotionNode(id: 'happy_trusting_sensitive', label: 'Sensitive'),
            EmotionNode(id: 'happy_trusting_intimate', label: 'Intimate'),
          ],
        ),
        EmotionNode(
          id: 'happy_optimistic',
          label: 'Optimistic',
          children: [
            EmotionNode(id: 'happy_optimistic_hopeful', label: 'Hopeful'),
            EmotionNode(id: 'happy_optimistic_inspired', label: 'Inspired'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'disgusted',
      label: 'Disgusted',
      children: [
        EmotionNode(
          id: 'disgusted_disapproving',
          label: 'Disapproving',
          children: [
            EmotionNode(
              id: 'disgusted_disapproving_judgmental',
              label: 'Judgmental',
            ),
            EmotionNode(
              id: 'disgusted_disapproving_embarrassed',
              label: 'Embarrassed',
            ),
          ],
        ),
        EmotionNode(
          id: 'disgusted_dissapointed',
          label: 'Dissapointed',
          children: [
            EmotionNode(
              id: 'disgusted_dissapointed_appalled',
              label: 'Appalled',
            ),
            EmotionNode(
              id: 'disgusted_dissapointed_revolted',
              label: 'Revolted',
            ),
          ],
        ),
        EmotionNode(
          id: 'disgusted_awful',
          label: 'Awful',
          children: [
            EmotionNode(id: 'disgusted_awful_nauseated', label: 'Nauseated'),
            EmotionNode(id: 'disgusted_awful_detestable', label: 'Detestable'),
          ],
        ),
        EmotionNode(
          id: 'disgusted_repelled',
          label: 'Repelled',
          children: [
            EmotionNode(id: 'disgusted_repelled_horrified', label: 'Horrified'),
            EmotionNode(id: 'disgusted_repelled_hesitant', label: 'Hesitant'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'angry',
      label: 'Angry',
      children: [
        EmotionNode(
          id: 'angry_let_down',
          label: 'Let Down',
          children: [
            EmotionNode(id: 'angry_let_down_betrayed', label: 'Betrayed'),
            EmotionNode(
              id: 'angry_let_down_disrespected',
              label: 'Disrespected',
            ),
          ],
        ),
        EmotionNode(
          id: 'angry_humiliated',
          label: 'Humiliated',
          children: [
            EmotionNode(
              id: 'angry_humiliated_disrespected',
              label: 'Disrespected',
            ),
            EmotionNode(id: 'angry_humiliated_ridiculed', label: 'Ridiculed'),
          ],
        ),
        EmotionNode(
          id: 'angry_bitter',
          label: 'Bitter',
          children: [
            EmotionNode(id: 'angry_bitter_indignant', label: 'Indignant'),
            EmotionNode(id: 'angry_bitter_violated', label: 'Violated'),
          ],
        ),
        EmotionNode(
          id: 'angry_mad',
          label: 'Mad',
          children: [
            EmotionNode(id: 'angry_mad_furious', label: 'Furious'),
            EmotionNode(id: 'angry_mad_jealous', label: 'Jealous'),
          ],
        ),
        EmotionNode(
          id: 'angry_aggressive',
          label: 'Aggressive',
          children: [
            EmotionNode(id: 'angry_aggressive_provoked', label: 'Provoked'),
            EmotionNode(id: 'angry_aggressive_hostile', label: 'Hostile'),
          ],
        ),
        EmotionNode(
          id: 'angry_frustrated',
          label: 'Frustrated',
          children: [
            EmotionNode(id: 'angry_frustrated_infuriated', label: 'Infuriated'),
            EmotionNode(id: 'angry_frustrated_annoyed', label: 'Annoyed'),
          ],
        ),
        EmotionNode(
          id: 'angry_distant',
          label: 'Distant',
          children: [
            EmotionNode(id: 'angry_distant_withdrawn', label: 'Withdrawn'),
            EmotionNode(id: 'angry_distant_numb', label: 'Numb'),
          ],
        ),
        EmotionNode(
          id: 'angry_critical',
          label: 'Critical',
          children: [
            EmotionNode(id: 'angry_critical_sceptical', label: 'Sceptical'),
            EmotionNode(id: 'angry_critical_dismissive', label: 'Dismissive'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'fearful',
      label: 'Fearful',
      children: [
        EmotionNode(
          id: 'fearful_scared',
          label: 'Scared',
          children: [
            EmotionNode(id: 'fearful_scared_helpless', label: 'Helpless'),
            EmotionNode(id: 'fearful_scared_frightened', label: 'Frightened'),
          ],
        ),
        EmotionNode(
          id: 'fearful_anxious',
          label: 'Anxious',
          children: [
            EmotionNode(id: 'fearful_anxious_worried', label: 'Worried'),
            EmotionNode(
              id: 'fearful_anxious_overwhelmed',
              label: 'Overwhelmed',
            ),
          ],
        ),
        EmotionNode(
          id: 'fearful_insecure',
          label: 'Insecure',
          children: [
            EmotionNode(id: 'fearful_insecure_inadequate', label: 'Inadequate'),
            EmotionNode(id: 'fearful_insecure_inferior', label: 'Inferior'),
          ],
        ),
        EmotionNode(
          id: 'fearful_weak',
          label: 'Weak',
          children: [
            EmotionNode(id: 'fearful_weak_worthless', label: 'Worthless'),
            EmotionNode(
              id: 'fearful_weak_insignificant',
              label: 'Insignificant',
            ),
          ],
        ),
        EmotionNode(
          id: 'fearful_rejected',
          label: 'Rejected',
          children: [
            EmotionNode(id: 'fearful_rejected_excluded', label: 'Excluded'),
            EmotionNode(id: 'fearful_rejected_persecuted', label: 'Persecuted'),
          ],
        ),
        EmotionNode(
          id: 'fearful_threatened',
          label: 'Threatened',
          children: [
            EmotionNode(id: 'fearful_threatened_exposed', label: 'Exposed'),
            EmotionNode(id: 'fearful_threatened_nervous', label: 'Nervous'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'bad',
      label: 'Bad',
      children: [
        EmotionNode(
          id: 'bad_bored',
          label: 'Bored',
          children: [
            EmotionNode(id: 'bad_bored_indefferent', label: 'Indefferent'),
            EmotionNode(id: 'bad_bored_apathetic', label: 'Apathetic'),
          ],
        ),
        EmotionNode(
          id: 'bad_busy',
          label: 'Busy',
          children: [
            EmotionNode(id: 'bad_busy_pressured', label: 'Pressured'),
            EmotionNode(id: 'bad_busy_rushed', label: 'Rushed'),
          ],
        ),
        EmotionNode(
          id: 'bad_stressed',
          label: 'Stressed',
          children: [
            EmotionNode(id: 'bad_stressed_overwhelmed', label: 'Overwhelmed'),
            EmotionNode(
              id: 'bad_stressed_out_of_control',
              label: 'Out Of Control',
            ),
          ],
        ),
        EmotionNode(
          id: 'bad_tied',
          label: 'Tied',
          children: [
            EmotionNode(id: 'bad_tied_sleepy', label: 'Sleepy'),
            EmotionNode(id: 'bad_tied_unfocused', label: 'Unfocused'),
          ],
        ),
      ],
    ),
    EmotionNode(
      id: 'surprised',
      label: 'Surprised',
      children: [
        EmotionNode(
          id: 'surprised_startled',
          label: 'Startled',
          children: [
            EmotionNode(id: 'surprised_startled_shocked', label: 'Shocked'),
            EmotionNode(id: 'surprised_startled_dismayed', label: 'Dismayed'),
          ],
        ),
        EmotionNode(
          id: 'surprised_confused',
          label: 'Confused',
          children: [
            EmotionNode(
              id: 'surprised_confused_disillusioned',
              label: 'Disillusioned',
            ),
            EmotionNode(id: 'surprised_confused_perplexed', label: 'Perplexed'),
          ],
        ),
        EmotionNode(
          id: 'surprised_amazed',
          label: 'Amazed',
          children: [
            EmotionNode(id: 'surprised_amazed_astonished', label: 'Astonished'),
            EmotionNode(id: 'surprised_amazed_awe', label: 'Awe'),
          ],
        ),
        EmotionNode(
          id: 'surprised_excited',
          label: 'Excited',
          children: [
            EmotionNode(id: 'surprised_excited_eager', label: 'Eager'),
            EmotionNode(id: 'surprised_excited_energetic', label: 'Energetic'),
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
    'joy': 'happy',
    'trust': 'happy',
    'fear': 'fearful',
    'surprise': 'surprised',
    'sadness': 'sad',
    'disgust': 'disgusted',
    'anger': 'angry',
    'anticipation': 'happy_optimistic',
    'joy_pride': 'happy_proud',
    'joy_gratitude': 'happy_peaceful_thankful',
    'joy_relief': 'happy_content_free',
    'trust_admiration': 'happy_accepting_respected',
    'trust_safety': 'fearful_threatened',
    'trust_acceptance': 'happy_accepting',
    'fear_anxiety': 'fearful_anxious',
    'fear_insecurity': 'fearful_insecure',
    'fear_worry': 'fearful_anxious_worried',
    'surprise_awe': 'surprised_amazed_awe',
    'surprise_confusion': 'surprised_confused',
    'surprise_shock': 'surprised_startled_shocked',
    'sadness_grief': 'sad_despair_grief',
    'disgust_uneasy': 'fearful_anxious',
    'anger_betrayed': 'angry_let_down_betrayed',
    'anticipation_hope': 'happy_optimistic_hopeful',
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
