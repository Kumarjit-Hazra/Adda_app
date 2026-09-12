import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../activities/engine/player_action.dart';
import 'brain_arena_engine.dart';
import 'brain_arena_models.dart';

class BrainArenaView extends ConsumerStatefulWidget {
  const BrainArenaView({super.key});

  @override
  ConsumerState<BrainArenaView> createState() => _BrainArenaViewState();
}

class _BrainArenaViewState extends ConsumerState<BrainArenaView> {
  final BrainArenaEngine _engine = BrainArenaEngine();
  late BrainArenaState _state;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? 'player_me';
    _state = _engine.createInitialState([myId, 'Aarav']);
  }

  void _dispatchAnswer(int optionIndex) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    setState(() => _selectedOption = optionIndex);

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'brain_arena',
      type: 'submit_answer',
      payload: {'optionIndex': optionIndex},
      clientSequence: _state.version,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _state = _engine.applyAction(_state, action);
        _selectedOption = null;
      });
      AudioService.playUiTap();
      HapticsService.lightTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _state.currentChallenge;
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final myScore = _state.scores[myId] ?? 0;

    return Container(
      padding: const EdgeInsets.all(AddaSpacing.lg),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [Color(0xFF231842), Color(0xFF130B29), Color(0xFF090417)],
        ),
      ),
      child: Column(
        children: [
          // Header with score & progress
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            backgroundColor: Colors.black45,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: AddaColors.violet,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Round ${_state.currentChallengeIndex + 1} / ${_state.challenges.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AddaColors.violet.withAlpha(40),
                    borderRadius: AddaRadius.radiusSm,
                  ),
                  child: Text(
                    'Score: $myScore pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AddaColors.violet,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AddaSpacing.lg),

          if (_state.isFinished) ...[
            Expanded(
              child: Center(
                child: SurfaceCard(
                  padding: const EdgeInsets.all(AddaSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: AddaSpacing.md),
                      Text(
                        'Arena Completed!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your final score: $myScore pts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AddaColors.amber,
                        ),
                      ),
                      const SizedBox(height: AddaSpacing.xl),
                      AppButton(
                        text: 'Play Again ⚡️',
                        onPressed: () {
                          setState(() {
                            _state = _engine.createInitialState(
                              _state.playerIds,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (challenge != null) ...[
            // Question Card
            Expanded(
              flex: 3,
              child: Center(
                child: SurfaceCard(
                  padding: const EdgeInsets.all(AddaSpacing.xxl),
                  borderColor: AddaColors.violet.withAlpha(80),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AddaColors.violet.withAlpha(30),
                          borderRadius: AddaRadius.radiusSm,
                        ),
                        child: Text(
                          challenge.category.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AddaColors.violet,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: AddaSpacing.lg),
                      Text(
                        challenge.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Options Grid
            Expanded(
              flex: 4,
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: List.generate(challenge.options.length, (index) {
                  final isSelected = _selectedOption == index;
                  return GestureDetector(
                    onTap: _selectedOption == null
                        ? () => _dispatchAnswer(index)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AddaColors.violet
                            : AddaColors.surfaceDark,
                        borderRadius: AddaRadius.radiusLg,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : AddaColors.borderLuminousDark,
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AddaColors.violet.withAlpha(100),
                              blurRadius: 12,
                            ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        challenge.options[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
