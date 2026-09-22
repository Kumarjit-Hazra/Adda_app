import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/widgets/app_button.dart';

class GameOverlay extends StatelessWidget {
  final bool isLoading;
  final bool isFinished;
  final String? resultMessage;
  final bool isVictory;
  final VoidCallback onRematch;
  final VoidCallback onExit;

  const GameOverlay({
    super.key,
    required this.isLoading,
    required this.isFinished,
    this.resultMessage,
    this.isVictory = false,
    required this.onRematch,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: Colors.black.withAlpha(150),
        child: const Center(
          child: CircularProgressIndicator(color: AddaColors.coral),
        ),
      );
    }

    if (isFinished) {
      return Container(
        color: Colors.black.withAlpha(150),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: AddaColors.surfaceDark,
              borderRadius: AddaRadius.radiusLg,
              border: Border.all(color: AddaColors.coral, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                if (resultMessage != null)
                  Text(
                    resultMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isVictory ? AddaColors.emerald : AddaColors.rose,
                    ),
                  ),
                const SizedBox(height: 32),
                AppButton(text: 'Rematch 🔄', onPressed: onRematch),
                const SizedBox(height: 12),
                AppButton.ghost(text: 'Back to Play', onPressed: onExit),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
