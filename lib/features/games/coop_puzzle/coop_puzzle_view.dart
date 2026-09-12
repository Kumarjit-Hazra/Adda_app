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
import 'coop_puzzle_engine.dart';
import 'coop_puzzle_models.dart';

class CoopPuzzleView extends ConsumerStatefulWidget {
  const CoopPuzzleView({super.key});

  @override
  ConsumerState<CoopPuzzleView> createState() => _CoopPuzzleViewState();
}

class _CoopPuzzleViewState extends ConsumerState<CoopPuzzleView> {
  final CoopPuzzleEngine _engine = CoopPuzzleEngine();
  late CoopPuzzleState _state;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? 'player_me';
    _state = _engine.createInitialState([myId, 'Aarav']);
  }

  void _dispatch(String type, Map<String, dynamic> payload) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'coop_puzzle',
      type: type,
      payload: payload,
      clientSequence: _state.version,
    );

    if (_engine.validateAction(_state, action)) {
      setState(() {
        _state = _engine.applyAction(_state, action);
      });
      AudioService.playUiTap();
      HapticsService.lightTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final myClues =
        _state.privateClues[myId] ??
        [
          '🔍 CLUE 1: The 1st digit is twice the 2nd digit.',
          '🔍 CLUE 2: The 4th digit is an odd number.',
        ];

    return Container(
      padding: const EdgeInsets.all(AddaSpacing.lg),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [Color(0xFF102836), Color(0xFF09161F), Color(0xFF040A0F)],
        ),
      ),
      child: Column(
        children: [
          // Private Clues Banner
          SurfaceCard(
            padding: const EdgeInsets.all(AddaSpacing.md),
            borderColor: AddaColors.cyan.withAlpha(80),
            backgroundColor: AddaColors.cyan.withAlpha(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.vpn_key_rounded,
                      color: AddaColors.cyan,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'CONFIDENTIAL: YOUR PRIVATE CLUES',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AddaColors.cyan,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Others have DIFFERENT clues! Talk over voice to solve the code together.',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                ...myClues.map(
                  (clue) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      clue,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AddaSpacing.md),

          // Safe Display with Digit Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final digit = index < _state.enteredCode.length
                  ? _state.enteredCode[index]
                  : '';
              return Container(
                width: 52,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: AddaRadius.radiusMd,
                  border: Border.all(
                    color: _state.isSolved
                        ? AddaColors.emerald
                        : AddaColors.cyan,
                    width: 2,
                  ),
                  boxShadow: [
                    if (_state.isSolved)
                      BoxShadow(
                        color: AddaColors.emerald.withAlpha(120),
                        blurRadius: 16,
                      ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  digit.isEmpty ? '—' : digit,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _state.isSolved ? AddaColors.emerald : Colors.white,
                  ),
                ),
              );
            }),
          ),

          if (_state.isSolved) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AddaColors.emerald.withAlpha(25),
                borderRadius: AddaRadius.radiusMd,
                border: Border.all(color: AddaColors.emerald),
              ),
              child: Column(
                children: [
                  const Text(
                    '🔓 VAULT UNLOCKED! SQUAD SUCCESS!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AddaColors.emerald,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'Play Again',
                    onPressed: () {
                      setState(() {
                        _state = _engine.createInitialState(_state.playerIds);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],

          if (_state.isFailed) ...[
            const SizedBox(height: 12),
            Text(
              'Incorrect combination! Clear and try again.',
              style: const TextStyle(
                color: AddaColors.rose,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],

          const Spacer(),

          // Keypad Grid
          if (!_state.isSolved)
            SizedBox(
              width: 240,
              child: Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['CLEAR', '0', 'ENTER'],
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: row.map((key) {
                          final isSpecial = key == 'CLEAR' || key == 'ENTER';
                          return GestureDetector(
                            onTap: () => _dispatch('press_key', {'key': key}),
                            child: Container(
                              width: 68,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSpecial
                                    ? (key == 'ENTER'
                                          ? AddaColors.emerald
                                          : AddaColors.rose.withAlpha(50))
                                    : AddaColors.surfaceDark,
                                borderRadius: AddaRadius.radiusMd,
                                border: Border.all(color: Colors.white24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                key,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: isSpecial ? 11 : 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
