import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/tokens/stickers.dart';
import '../providers/room_provider.dart';
import 'floating_reaction_overlay.dart';

class CompactGameHud extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onOpenChat;

  const CompactGameHud({
    super.key,
    required this.onClose,
    required this.onOpenChat,
  });

  @override
  ConsumerState<CompactGameHud> createState() => _CompactGameHudState();
}

class _CompactGameHudState extends ConsumerState<CompactGameHud> {
  bool _showStickerDock = false;

  void _sendSticker(BuildContext context, AddaSticker sticker) {
    try {
      FloatingReactionOverlay.of(context).spawnSticker(sticker.emoji);
    } catch (_) {}

    ref.read(roomProvider.notifier).sendReaction(sticker.emoji);
    AudioService.playReaction();
    HapticsService.mediumImpact();
    setState(() => _showStickerDock = false);
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);
    if (room == null) return const SizedBox.shrink();

    final isSolo = room.isSoloMode;
    final isVoiceJoined = room.isVoiceJoined;

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AddaSpacing.sm,
              vertical: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Exit/Minimize
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: AddaRadius.radiusFull,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Back to Lounge',
                    onPressed: widget.onClose,
                  ),
                ),

                // Center: Solo Badge or Optional Voice Pill
                if (isSolo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AddaColors.violet.withAlpha(40),
                      borderRadius: AddaRadius.radiusFull,
                      border: Border.all(
                        color: AddaColors.violet.withAlpha(100),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('🤖', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Text(
                          'Solo vs Bots',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildVoicePill(isVoiceJoined),

                // Right: Sticker Tray & Chat Drawer Toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _showStickerDock
                            ? AddaColors.coral
                            : Colors.black54,
                        borderRadius: AddaRadius.radiusFull,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.add_reaction_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Send Sticker',
                        onPressed: () {
                          setState(() => _showStickerDock = !_showStickerDock);
                          AudioService.playUiTap();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: AddaRadius.radiusFull,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Room Chat',
                        onPressed: widget.onOpenChat,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Sticker Dock Popup
        if (_showStickerDock)
          Positioned(
            top: 60,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(AddaSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFF161928),
                borderRadius: AddaRadius.radiusXl,
                border: Border.all(
                  color: AddaColors.coral.withAlpha(100),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Tap to React 💥',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: AddaSticker.stickerPack.take(5).map((stk) {
                      return GestureDetector(
                        onTap: () => _sendSticker(context, stk),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: AddaRadius.radiusMd,
                          ),
                          child: Text(
                            stk.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: AddaSticker.stickerPack.skip(5).take(3).map((
                      stk,
                    ) {
                      return GestureDetector(
                        onTap: () => _sendSticker(context, stk),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: AddaRadius.radiusMd,
                          ),
                          child: Text(
                            stk.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoicePill(bool isVoiceJoined) {
    if (!isVoiceJoined) {
      return GestureDetector(
        onTap: () => ref.read(roomProvider.notifier).joinVoiceChat(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: AddaRadius.radiusFull,
            border: Border.all(
              color: AddaColors.emerald.withAlpha(120),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(color: AddaColors.emerald.withAlpha(40), blurRadius: 8),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.mic_none_rounded, color: AddaColors.emerald, size: 16),
              SizedBox(width: 6),
              Text(
                'Join Voice',
                style: TextStyle(
                  color: AddaColors.emerald,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F261C),
        borderRadius: AddaRadius.radiusFull,
        border: Border.all(color: AddaColors.emerald),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AddaColors.emerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Live VC',
            style: TextStyle(
              color: AddaColors.emerald,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => ref.read(roomProvider.notifier).toggleMic(),
          ),
          IconButton(
            icon: const Icon(
              Icons.call_end_rounded,
              color: AddaColors.coral,
              size: 16,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => ref.read(roomProvider.notifier).leaveVoiceChat(),
          ),
        ],
      ),
    );
  }
}
