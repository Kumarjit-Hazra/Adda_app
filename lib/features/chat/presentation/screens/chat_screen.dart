import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/adda_top_bar.dart';
import '../../../../shared/design_system/widgets/app_avatar.dart';
import '../../../../shared/design_system/widgets/app_scaffold.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _tabIndex = 0;

  final List<Map<String, dynamic>> _threads = const [
    {
      'name': 'Chai Pe Charcha',
      'isGroup': true,
      'isOnline': true,
      'lastMessage': 'Anyone up for 29 Cards tonight?',
      'time': '2m ago',
      'unreadCount': 2,
      'hasGameInvite': true,
      'gameName': '29 Cards',
    },
    {
      'name': 'Priya S.',
      'isGroup': false,
      'isOnline': true,
      'lastMessage': 'GG! That UNO reverse was wild 😂',
      'time': '15m ago',
      'unreadCount': 0,
      'hasGameInvite': false,
    },
    {
      'name': 'Late Night Adda',
      'isGroup': true,
      'isOnline': true,
      'lastMessage': 'Mystery Crypt session scheduled for 10 PM',
      'time': '1h ago',
      'unreadCount': 5,
      'hasGameInvite': false,
    },
    {
      'name': 'Rohan M.',
      'isGroup': false,
      'isOnline': false,
      'lastMessage': 'Are you free for Bluff Masters tomorrow?',
      'time': '3h ago',
      'unreadCount': 0,
      'hasGameInvite': false,
    },
    {
      'name': 'Weekend Warriors',
      'isGroup': true,
      'isOnline': false,
      'lastMessage': 'Court Piece championship this Saturday! 🏆',
      'time': '5h ago',
      'unreadCount': 0,
      'hasGameInvite': true,
      'gameName': 'Court Piece',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  content: Text(
                    'Direct messaging will be activated in Phase 8.',
                  ),
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
            child: Builder(
              builder: (context) {
                final items = _tabIndex == 1
                    ? _threads.where((t) => t['isGroup'] == true).toList()
                    : _tabIndex == 2
                    ? _threads.where((t) => t['hasGameInvite'] == true).toList()
                    : _threads;

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
                    final hasInvite = thread['hasGameInvite'] == true;
                    final unread = (thread['unreadCount'] as int?) ?? 0;

                    return SurfaceCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Opening thread "${thread['name']}" (Phase 8)',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          AppAvatar(
                            name: thread['name'] as String,
                            size: 46,
                            isOnline: thread['isOnline'] == true,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        thread['name'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      thread['time'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AddaColors.textMutedDark
                                            : AddaColors.textMutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (hasInvite) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: AddaColors.amber.withAlpha(40),
                                          borderRadius: AddaRadius.radiusXs,
                                        ),
                                        child: Text(
                                          '🎮 ${thread['gameName']}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AddaColors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Text(
                                        thread['lastMessage'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: unread > 0
                                              ? (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                              : (isDark
                                                    ? AddaColors
                                                          .textSecondaryDark
                                                    : AddaColors
                                                          .textSecondaryLight),
                                          fontWeight: unread > 0
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (unread > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: AddaColors.coral,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$unread',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
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
