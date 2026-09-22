import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../application/daily_providers.dart';

class DailyAddaCard extends ConsumerStatefulWidget {
  const DailyAddaCard({super.key});

  @override
  ConsumerState<DailyAddaCard> createState() => _DailyAddaCardState();
}

class _DailyAddaCardState extends ConsumerState<DailyAddaCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _shareAnswer(String prompt, String answer) async {
    if (answer.trim().isEmpty) return;

    // Mark as answered in DailyState
    ref.read(dailyStateProvider.notifier).markAddaAnswered();

    // Clear the text so the UI immediately updates to the success state
    _controller.clear();

    final shareText =
        'ADDA Daily Question: $prompt\n\nMy Answer: $answer\n\nJoin the Adda!';

    try {
      // ignore: deprecated_member_use
      await Share.share(shareText);
    } catch (e) {
      // Ignore share sheet cancellation or platform errors.
      // Completion is tied to the intent to share, not the OS result.
      debugPrint('Share sheet dismissed or failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyStateAsync = ref.watch(dailyStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dailyStateAsync.when(
      data: (dailyState) {
        return SurfaceCard(
          padding: const EdgeInsets.all(AddaSpacing.lg),
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF2C243B), Color(0xFF131826)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFFF0F5), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_rounded,
                    color: AddaColors.rose,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TODAY\'S ADDA',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AddaColors.rose,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AddaSpacing.md),
              Text(
                dailyState.dailyPrompt,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AddaSpacing.lg),

              if (dailyState.isAddaAnswered && _controller.text.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AddaColors.emerald.withValues(alpha: 20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AddaColors.emerald.withValues(alpha: 40),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AddaColors.emerald,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You answered today\'s Adda! Check back tomorrow for a new prompt.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Type your answer here...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.white70,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: AddaSpacing.md),
                    AppButton(
                      text: 'Share your answer',
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      onPressed: _controller.text.trim().isNotEmpty
                          ? () => _shareAnswer(
                              dailyState.dailyPrompt,
                              _controller.text,
                            )
                          : null,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
      loading: () => const SurfaceCard(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox(),
    );
  }
}
