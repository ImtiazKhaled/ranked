import 'package:flutter/material.dart';

/// A node in the emotion wheel (any tier).
class EmotionNode {
  final String name;
  final String emoji;
  final List<EmotionNode> children;

  const EmotionNode(this.name, this.emoji, [this.children = const []]);
}

/// Signature colour for each of the 7 primary emotions. Secondary/tertiary
/// items are tinted from their primary's colour.
const Map<String, Color> kPrimaryEmotionColors = {
  'Angry': Color(0xFFEF4444), // red
  'Fearful': Color(0xFF8B5CF6), // violet
  'Happy': Color(0xFFF59E0B), // amber
  'Disgusted': Color(0xFF22C55E), // green
  'Sad': Color(0xFF3B82F6), // blue
  'Bad': Color(0xFF9CA3AF), // grey
  'Surprised': Color(0xFF06B6D4), // cyan
};

/// Returns the signature colour for whichever primary a node belongs to.
Color primaryEmotionColor(String primary) =>
    kPrimaryEmotionColors[primary] ?? const Color(0xFF9CA3AF);

/// The full 3-tier emotion taxonomy (7 primaries -> secondaries -> tertiaries).
const List<EmotionNode> kEmotionWheel = [
  EmotionNode('Angry', '😠', [
    EmotionNode('Let Down', '😔', [
      EmotionNode('Betrayed', '💔'),
      EmotionNode('Resentful', '😒'),
    ]),
    EmotionNode('Humiliated', '🫠', [
      EmotionNode('Disrespected', '🙄'),
      EmotionNode('Ridiculed', '🤡'),
    ]),
    EmotionNode('Bitter', '😖', [
      EmotionNode('Indignant', '😤'),
      EmotionNode('Violated', '😵'),
    ]),
    EmotionNode('Mad', '😡', [
      EmotionNode('Furious', '🤬'),
      EmotionNode('Jealous', '🐍'),
    ]),
    EmotionNode('Aggressive', '👊', [
      EmotionNode('Provoked', '😾'),
      EmotionNode('Hostile', '😈'),
    ]),
    EmotionNode('Frustrated', '😣', [
      EmotionNode('Infuriated', '🥵'),
      EmotionNode('Annoyed', '😑'),
    ]),
    EmotionNode('Distant', '😶‍🌫️', [
      EmotionNode('Withdrawn', '🐢'),
      EmotionNode('Numb', '🥶'),
    ]),
    EmotionNode('Critical', '🧐', [
      EmotionNode('Skeptical', '🤨'),
      EmotionNode('Dismissive', '🫥'),
    ]),
  ]),
  EmotionNode('Fearful', '😨', [
    EmotionNode('Scared', '😱', [
      EmotionNode('Helpless', '😩'),
      EmotionNode('Frightened', '👻'),
    ]),
    EmotionNode('Anxious', '😰', [
      EmotionNode('Overwhelmed', '🌊'),
      EmotionNode('Worried', '😟'),
    ]),
    EmotionNode('Insecure', '🫣', [
      EmotionNode('Inadequate', '🫤'),
      EmotionNode('Inferior', '🐜'),
    ]),
    EmotionNode('Weak', '😮‍💨', [
      EmotionNode('Worthless', '🥀'),
      EmotionNode('Insignificant', '🦠'),
    ]),
    EmotionNode('Rejected', '🥹', [
      EmotionNode('Excluded', '🙅'),
      EmotionNode('Persecuted', '🎯'),
    ]),
    EmotionNode('Threatened', '⚠️', [
      EmotionNode('Nervous', '😬'),
      EmotionNode('Exposed', '👀'),
    ]),
  ]),
  EmotionNode('Happy', '😊', [
    EmotionNode('Playful', '😜', [
      EmotionNode('Aroused', '😏'),
      EmotionNode('Cheeky', '😝'),
    ]),
    EmotionNode('Content', '😌', [
      EmotionNode('Free', '🕊️'),
      EmotionNode('Joyful', '😁'),
    ]),
    EmotionNode('Interested', '🤓', [
      EmotionNode('Curious', '🐱'),
      EmotionNode('Inquisitive', '🦉'),
    ]),
    EmotionNode('Proud', '🦚', [
      EmotionNode('Successful', '🏆'),
      EmotionNode('Confident', '💪'),
    ]),
    EmotionNode('Accepted', '🤗', [
      EmotionNode('Respected', '🫡'),
      EmotionNode('Valued', '💎'),
    ]),
    EmotionNode('Powerful', '🦸', [
      EmotionNode('Courageous', '🦁'),
      EmotionNode('Creative', '🎨'),
    ]),
    EmotionNode('Peaceful', '🧘', [
      EmotionNode('Loving', '❤️'),
      EmotionNode('Thankful', '🙏'),
    ]),
    EmotionNode('Trusting', '🤝', [
      EmotionNode('Sensitive', '🌸'),
      EmotionNode('Intimate', '🫶'),
    ]),
    EmotionNode('Optimistic', '🌞', [
      EmotionNode('Hopeful', '🌱'),
      EmotionNode('Inspired', '💡'),
    ]),
  ]),
  EmotionNode('Disgusted', '🤢', [
    EmotionNode('Disapproving', '👎', [
      EmotionNode('Judgmental', '⚖️'),
      EmotionNode('Embarrassed', '😳'),
    ]),
    EmotionNode('Disappointed', '😞', [
      EmotionNode('Appalled', '😧'),
      EmotionNode('Revolted', '🤮'),
    ]),
    EmotionNode('Awful', '💩', [
      EmotionNode('Nauseated', '🥴'),
      EmotionNode('Detestable', '👿'),
    ]),
    EmotionNode('Repelled', '🦨', [
      EmotionNode('Horrified', '🧟'),
      EmotionNode('Hesitant', '✋'),
    ]),
  ]),
  EmotionNode('Sad', '😢', [
    EmotionNode('Lonely', '🐺', [
      EmotionNode('Isolated', '🏝️'),
      EmotionNode('Abandoned', '😿'),
    ]),
    EmotionNode('Vulnerable', '🐣', [
      EmotionNode('Fragile', '🥚'),
      EmotionNode('Victimised', '🥺'),
    ]),
    EmotionNode('Despair', '😭', [
      EmotionNode('Grief', '🖤'),
      EmotionNode('Powerless', '🪫'),
    ]),
    EmotionNode('Guilty', '🫢', [
      EmotionNode('Ashamed', '🙈'),
      EmotionNode('Remorseful', '🙇'),
    ]),
    EmotionNode('Depressed', '🌧️', [
      EmotionNode('Inferior', '🐜'),
      EmotionNode('Empty', '🕳️'),
    ]),
    EmotionNode('Hurt', '🤕', [
      EmotionNode('Disappointed', '😞'),
      EmotionNode('Embarrassed', '😳'),
    ]),
  ]),
  EmotionNode('Bad', '😕', [
    EmotionNode('Bored', '🥱', [
      EmotionNode('Indifferent', '🤷'),
      EmotionNode('Apathetic', '😶'),
    ]),
    EmotionNode('Busy', '🐝', [
      EmotionNode('Pressured', '🤯'),
      EmotionNode('Rushed', '🏃'),
    ]),
    EmotionNode('Stressed', '😫', [
      EmotionNode('Overwhelmed', '🌊'),
      EmotionNode('Out of Control', '🎢'),
    ]),
    EmotionNode('Tired', '😴', [
      EmotionNode('Sleepy', '😪'),
      EmotionNode('Unfocused', '😵‍💫'),
    ]),
  ]),
  EmotionNode('Surprised', '😲', [
    EmotionNode('Startled', '🫨', [
      EmotionNode('Shocked', '😮'),
      EmotionNode('Dismayed', '😦'),
    ]),
    EmotionNode('Confused', '🤔', [
      EmotionNode('Disillusioned', '🎭'),
      EmotionNode('Perplexed', '🧩'),
    ]),
    EmotionNode('Amazed', '🤩', [
      EmotionNode('Astonished', '😯'),
      EmotionNode('Awe', '🌌'),
    ]),
    EmotionNode('Excited', '🥳', [
      EmotionNode('Eager', '🙌'),
      EmotionNode('Energetic', '⚡'),
    ]),
  ]),
];
