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
import 'couple_mode_engine.dart';
import 'couple_mode_models.dart';

class CoupleModeView extends ConsumerStatefulWidget {
  const CoupleModeView({super.key});

  @override
  ConsumerState<CoupleModeView> createState() => _CoupleModeViewState();
}

class _CoupleModeViewState extends ConsumerState<CoupleModeView> {
  final CoupleModeEngine _engine = CoupleModeEngine();
  late CoupleModeState _state;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? 'player_me';
    _state = _engine.createInitialState([myId, 'Partner']);
  }

  void _submitMyAnswer(String answer) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    setState(() => _selectedAnswer = answer);
    AudioService.playUiTap();
    HapticsService.lightTap();

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'couple_mode',
      type: 'submit_answer',
      payload: {'answer': answer},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });

    // Simulate partner response if not yet answered
    if (_state.playerIds.length > 1) {
      final partnerId = _state.playerIds[1];
      if (!_state.currentAnswers.containsKey(partnerId)) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          final q = _state.currentQuestion;
          if (q == null) return;
          // Partner picks answer (sometimes same for sync)
          final partnerAnswer = q.options.isNotEmpty ? q.options.first : 'Love';
          final partnerAction = PlayerAction(
            actionId: const Uuid().v4(),
            playerId: partnerId,
            activityId: 'couple_mode',
            type: 'submit_answer',
            payload: {'answer': partnerAnswer},
            clientSequence: _state.version,
          );
          setState(() {
            _state = _engine.applyAction(_state, partnerAction);
          });
          HapticsService.mediumImpact();
        });
      }
    }
  }

  void _nextQuestion() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'couple_mode',
      type: 'next_question',
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
      _selectedAnswer = null;
    });
    AudioService.playUiTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_state.isFinished) {
      final result = _engine.getResult(_state);
      return _buildFinishedView(isDark, result);
    }

    final question = _state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final myAnswer = _state.currentAnswers[myId];
    final partnerId = _state.playerIds.length > 1 ? _state.playerIds[1] : null;
    final partnerAnswer = partnerId != null
        ? _state.currentAnswers[partnerId]
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1E1020), const Color(0xFF0F0B14)]
              : [const Color(0xFFFFF0F5), const Color(0xFFF9E8EE)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AddaSpacing.md,
            vertical: AddaSpacing.sm,
          ),
          child: Column(
            children: [
              _buildHeader(isDark),
              const SizedBox(height: AddaSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildQuestionCard(question, isDark),
                      const SizedBox(height: AddaSpacing.md),
                      if (!_state.answersRevealed)
                        _buildOptions(question, myAnswer, isDark)
                      else
                        _buildRevealSection(
                          myAnswer,
                          partnerAnswer,
                          question,
                          isDark,
                        ),
                    ],
                  ),
                ),
              ),
              if (_state.answersRevealed) ...[
                const SizedBox(height: AddaSpacing.sm),
                AppButton(
                  text:
                      _state.currentQuestionIndex + 1 < _state.questions.length
                      ? 'Next Question ❤️'
                      : 'View Couple Report ✨',
                  onPressed: _nextQuestion,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AddaSpacing.sm),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: AddaColors.rose,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Intimacy Meter: ${_state.intimacyMeter}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                'Q ${_state.currentQuestionIndex + 1}/${_state.questions.length}',
                style: TextStyle(
                  color: isDark
                      ? AddaColors.textMutedDark
                      : AddaColors.textMutedLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _state.intimacyMeter / 100,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AddaColors.rose),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(CoupleQuestion question, bool isDark) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AddaSpacing.lg),
      borderColor: AddaColors.rose.withAlpha(50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AddaColors.rose.withAlpha(30),
              borderRadius: AddaRadius.radiusSm,
            ),
            child: Text(
              question.category.name.toUpperCase(),
              style: const TextStyle(
                color: AddaColors.rose,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: AddaSpacing.md),
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(CoupleQuestion question, String? myAnswer, bool isDark) {
    if (myAnswer != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AddaSpacing.xl),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AddaColors.rose),
            const SizedBox(height: AddaSpacing.md),
            const Text(
              'Your answer is locked! Waiting for partner...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: question.options.map((option) {
        final isSelected = _selectedAnswer == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: AddaSpacing.sm),
          child: SurfaceCard(
            onTap: () => _submitMyAnswer(option),
            borderColor: isSelected ? AddaColors.rose : Colors.transparent,
            backgroundColor: isSelected
                ? AddaColors.rose.withAlpha(40)
                : (isDark ? AddaColors.surfaceDark : Colors.white),
            padding: const EdgeInsets.symmetric(
              horizontal: AddaSpacing.md,
              vertical: AddaSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AddaColors.rose : Colors.white24,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRevealSection(
    String? myAnswer,
    String? partnerAnswer,
    CoupleQuestion question,
    bool isDark,
  ) {
    final isMatch =
        myAnswer != null && partnerAnswer != null && myAnswer == partnerAnswer;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AddaSpacing.md),
          decoration: BoxDecoration(
            color: isMatch
                ? AddaColors.emerald.withAlpha(30)
                : AddaColors.rose.withAlpha(30),
            borderRadius: AddaRadius.radiusMd,
            border: Border.all(
              color: isMatch ? AddaColors.emerald : AddaColors.rose,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMatch ? Icons.stars_rounded : Icons.favorite_border_rounded,
                color: isMatch ? AddaColors.emerald : AddaColors.rose,
              ),
              const SizedBox(width: 8),
              Text(
                isMatch
                    ? 'Mind Sync! You both picked the same!'
                    : 'Different Perspectives! Talk it out!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isMatch ? AddaColors.emerald : AddaColors.rose,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AddaSpacing.md),
        Row(
          children: [
            Expanded(
              child: SurfaceCard(
                padding: const EdgeInsets.all(AddaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You Picked',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      myAnswer ?? 'No answer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SurfaceCard(
                padding: const EdgeInsets.all(AddaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Partner Picked',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partnerAnswer ?? 'Pending',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AddaSpacing.md),
        if (question.deepPrompt.isNotEmpty)
          SurfaceCard(
            padding: const EdgeInsets.all(AddaSpacing.md),
            backgroundColor: AddaColors.violet.withAlpha(25),
            borderColor: AddaColors.violet.withAlpha(80),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: AddaColors.violet,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voice Conversation Spark',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AddaColors.violet,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        question.deepPrompt,
                        style: const TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFinishedView(bool isDark, Map<String, dynamic> result) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AddaSpacing.xl),
        child: SurfaceCard(
          padding: const EdgeInsets.all(AddaSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: AddaColors.rose,
                size: 64,
              ),
              const SizedBox(height: AddaSpacing.md),
              Text(
                result['verdict'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AddaSpacing.sm),
              Text(
                'Final Intimacy Sync: ${result['intimacyMeter']}%',
                style: const TextStyle(
                  fontSize: 16,
                  color: AddaColors.rose,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AddaSpacing.xl),
              AppButton(
                text: 'Play Another Sanctuary Session',
                onPressed: () {
                  final user = ref.read(authProvider).valueOrNull;
                  final myId = user?.id ?? 'player_me';
                  setState(() {
                    _state = _engine.createInitialState([myId, 'Partner']);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
