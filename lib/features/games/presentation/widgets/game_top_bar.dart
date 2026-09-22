import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/adda_top_bar.dart';

class GameTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isFinished;
  final VoidCallback onRematch;
  final VoidCallback onExit;

  const GameTopBar({
    super.key,
    required this.title,
    required this.isFinished,
    required this.onRematch,
    required this.onExit,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AddaTopBar(
      contextBadge: 'ARCADE',
      contextTitle: title,
      actions: [
        if (isFinished)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AddaColors.coral),
            onPressed: onRematch,
            tooltip: 'Rematch',
          ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () {
            if (!isFinished) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AddaColors.surfaceDark,
                  title: const Text(
                    'Leave game?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Your current game will be abandoned.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        'Stay',
                        style: TextStyle(color: AddaColors.emerald),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onExit();
                      },
                      child: const Text(
                        'Leave',
                        style: TextStyle(color: AddaColors.rose),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              onExit();
            }
          },
          tooltip: 'Exit Game',
        ),
      ],
    );
  }
}
