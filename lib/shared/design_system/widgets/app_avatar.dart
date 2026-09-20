import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Glowing social avatar with speaking wave border and presence badge.
class AppAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String? avatarSeed;
  final double size;
  final bool isSpeaking;
  final bool isOnline;
  final bool isBot;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.avatarSeed,
    this.size = 44,
    this.isSpeaking = false,
    this.isOnline = true,
    this.isBot = false,
    this.onTap,
  });

  static const Map<String, String> seedEmojis = {
    'seed_chai': '☕️',
    'seed_tiger': '🐯',
    'seed_phoenix': '🦅',
    'seed_bluff': '🎭',
    'seed_cosmic': '🚀',
    'seed_neon': '⚡️',
    'seed_wizard': '🧙',
    'seed_joker': '🃏',
  };

  static String? getSeedEmoji(String? seed) {
    if (seed == null || seed.isEmpty) return null;
    if (seedEmojis.containsKey(seed)) return seedEmojis[seed];
    const fallbackEmojis = [
      '☕️',
      '🐯',
      '🦅',
      '🎭',
      '🚀',
      '⚡️',
      '🧙',
      '🃏',
      '🦁',
      '🌟',
      '🎮',
      '🔥',
    ];
    final hash = seed.codeUnits.fold(0, (prev, elem) => prev + elem);
    return fallbackEmojis[hash % fallbackEmojis.length];
  }

  Color _generateBgColor(String text) {
    final hash = text.codeUnits.fold(0, (prev, elem) => prev + elem);
    const colors = [
      AddaColors.coral,
      AddaColors.amber,
      AddaColors.violet,
      AddaColors.cyan,
      Color(0xFF3B82F6),
      Color(0xFFEC4899),
      AddaColors.emerald,
      AddaColors.rose,
    ];
    return colors[hash % colors.length];
  }

  String _getInitials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final seedKey = avatarSeed != null && avatarSeed!.isNotEmpty
        ? avatarSeed!
        : name;
    final bg = _generateBgColor(seedKey);
    final emoji = getSeedEmoji(avatarSeed);

    Widget avatar = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [bg, bg.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isSpeaking ? AddaColors.emerald : Colors.white.withAlpha(40),
          width: isSpeaking ? 2.5 : 1.2,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: AddaColors.emerald.withAlpha(120),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji, style: TextStyle(fontSize: size * 0.46))
          : Text(
              _getInitials(name),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.38,
              ),
            ),
    );

    final showBot = isBot || name.contains('Bot') || name.contains('🤖');

    if (showBot) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
                shape: BoxShape.circle,
                border: Border.all(color: AddaColors.violet, width: 1.2),
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 10)),
            ),
          ),
        ],
      );
    } else if (isOnline) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AddaColors.emerald,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
