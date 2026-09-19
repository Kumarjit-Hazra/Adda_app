import 'package:flutter/material.dart';
import 'colors.dart';

class AddaSticker {
  final String id;
  final String label;
  final String emoji;
  final Color accentColor;
  final String tagline;

  const AddaSticker({
    required this.id,
    required this.label,
    required this.emoji,
    required this.accentColor,
    required this.tagline,
  });

  static const List<AddaSticker> stickerPack = [
    AddaSticker(
      id: 'stk_chai',
      label: 'Kulhad Chai',
      emoji: '☕',
      accentColor: AddaColors.amber,
      tagline: 'Chai break shuru!',
    ),
    AddaSticker(
      id: 'stk_fire',
      label: 'Fire Shot',
      emoji: '🔥',
      accentColor: AddaColors.coral,
      tagline: 'Kya game chal raha!',
    ),
    AddaSticker(
      id: 'stk_bluff',
      label: 'Pakda Gaya!',
      emoji: '🎭',
      accentColor: AddaColors.rose,
      tagline: 'Full jhoot pakda!',
    ),
    AddaSticker(
      id: 'stk_brain',
      label: 'Mind Blown',
      emoji: '🤯',
      accentColor: AddaColors.violet,
      tagline: 'Arrey baap re!',
    ),
    AddaSticker(
      id: 'stk_gg',
      label: 'Game Over GG',
      emoji: '🏆',
      accentColor: AddaColors.emerald,
      tagline: 'Khatam! Tata! Bye Bye!',
    ),
    AddaSticker(
      id: 'stk_love',
      label: 'Dil Se',
      emoji: '💖',
      accentColor: AddaColors.rose,
      tagline: 'Pure vibes!',
    ),
    AddaSticker(
      id: 'stk_speed',
      label: 'Lightning',
      emoji: '⚡',
      accentColor: AddaColors.cyan,
      tagline: 'Speed 100!',
    ),
    AddaSticker(
      id: 'stk_clown',
      label: 'Arey Yaar',
      emoji: '🤡',
      accentColor: AddaColors.amber,
      tagline: 'Kya kar diya tune!',
    ),
  ];
}
