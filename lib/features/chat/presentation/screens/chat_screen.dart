import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/adda_top_bar.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../application/chat_providers.dart';
import '../widgets/conversation_tile.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversationsAsync = ref.watch(conversationsProvider);

    return AppScaffold(
      appBar: AddaTopBar(
        contextBadge: 'MESSAGES',
        contextTitle: 'Chat',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 24),
            tooltip: 'New Message',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Direct messaging creation flow coming soon.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter segmented tabs
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AddaSpacing.lg,
              vertical: AddaSpacing.xs,
            ),
            child: Row(
              children: [
                _buildSegment('All Chats', 0),
                const SizedBox(width: 8),
                _buildSegment('Spaces', 1),
                const SizedBox(width: 8),
                _buildSegment('Game Invites', 2),
              ],
            ),
          ),
          const SizedBox(height: AddaSpacing.xs),
          const Divider(height: 1),

          // Thread List
          Expanded(
            child: conversationsAsync.when(
              data: (threads) {
                final items = _tabIndex == 1
                    ? threads.where((t) => t.isGroup == true).toList()
                    : _tabIndex == 2
                    ? threads.where((t) => t.gameInviteId != null).toList()
                    : threads;

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No conversations in this section',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AddaSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final thread = items[index];
                    return ConversationTile(conversation: thread);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error loading chats: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, int index) {
    final isSelected = _tabIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AddaColors.surfaceElevatedDark : Colors.white)
                : Colors.transparent,
            borderRadius: AddaRadius.radiusSm,
            border: Border.all(
              color: isSelected ? AddaColors.coral : Colors.transparent,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AddaColors.coral
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
