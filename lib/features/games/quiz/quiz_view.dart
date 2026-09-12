import 'dart:async';
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
import 'quiz_engine.dart';
import 'quiz_models.dart';

class QuizView extends ConsumerStatefulWidget {
  const QuizView({super.key});

  @override
  ConsumerState<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends ConsumerState<QuizView> {
  final QuizEngine _engine = QuizEngine();
  late QuizState _state;
  int? _selectedOption;
  int _secondsLeft = 15;
  Timer? _timer;
  DateTime _questionStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? 'player_me';
    _state = _engine.createInitialState([myId, 'Rohan', 'Sneha']);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 15;
    _questionStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        _onTimeOut();
      }
    });

    // Simulate opponent answers
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted || _state.phase != QuizRoundPhase.answering) return;
      final q = _state.currentQuestion;
      if (q == null) return;
      final rohanAction = PlayerAction(
        actionId: const Uuid().v4(),
        playerId: 'Rohan',
        activityId: 'quiz_clash',
        type: 'answer_question',
        payload: {'optionIndex': q.correctIndex, 'timeTakenMs': 1800},
        clientSequence: _state.version,
      );
      setState(() {
        _state = _engine.applyAction(_state, rohanAction);
      });
    });
  }

  void _onTimeOut() {
    if (_state.phase == QuizRoundPhase.answering) {
      final user = ref.read(authProvider).valueOrNull;
      final myId = user?.id ?? _state.playerIds.first;
      if (!_state.answersForCurrent.containsKey(myId)) {
        // User didn't answer in time, reveal round
        final action = PlayerAction(
          actionId: const Uuid().v4(),
          playerId: myId,
          activityId: 'quiz_clash',
          type: 'reveal_round',
          payload: {},
          clientSequence: _state.version,
        );
        setState(() {
          _state = _engine.applyAction(_state, action);
        });
      }
    }
  }

  void _chooseOption(int index) {
    if (_state.phase != QuizRoundPhase.answering || _selectedOption != null) {
      return;
    }

    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final timeTakenMs = DateTime.now()
        .difference(_questionStartTime)
        .inMilliseconds;

    setState(() => _selectedOption = index);

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'quiz_clash',
      type: 'answer_question',
      payload: {'optionIndex': index, 'timeTakenMs': timeTakenMs},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });

    final currentQ = _state.currentQuestion;
    if (currentQ != null && index == currentQ.correctIndex) {
      AudioService.playUiTap();
      HapticsService.mediumImpact();
    } else {
      HapticsService.lightTap();
    }
  }

  void _nextQuestion() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'quiz_clash',
      type: 'next_question',
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
      _selectedOption = null;
    });

    if (!_state.isFinished) {
      _startTimer();
    }
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

    return Container(
      color: isDark ? AddaColors.bgDark : AddaColors.bgLight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AddaSpacing.md,
            vertical: AddaSpacing.sm,
          ),
          child: Column(
            children: [
              _buildTopBar(question, isDark),
              const SizedBox(height: AddaSpacing.md),
              _buildQuestionCard(question, isDark),
              const SizedBox(height: AddaSpacing.md),
              Expanded(
                child: ListView.builder(
                  itemCount: question.options.length,
                  itemBuilder: (context, index) =>
                      _buildOptionTile(index, question, isDark),
                ),
              ),
              if (_state.phase == QuizRoundPhase.reveal) ...[
                if (question.explanation.isNotEmpty)
                  SurfaceCard(
                    padding: const EdgeInsets.all(AddaSpacing.sm),
                    borderColor: AddaColors.amber.withAlpha(80),
                    child: Text(
                      '💡 ${question.explanation}',
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                const SizedBox(height: AddaSpacing.sm),
                AppButton(
                  text:
                      _state.currentQuestionIndex + 1 < _state.questions.length
                      ? 'Next Question ⚡'
                      : 'View Final Podiums 🏆',
                  onPressed: _nextQuestion,
                ),
              ],
              const SizedBox(height: AddaSpacing.sm),
              _buildScoreboard(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(QuizQuestion question, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AddaColors.violet.withAlpha(30),
            borderRadius: AddaRadius.radiusSm,
            border: Border.all(color: AddaColors.violet.withAlpha(80)),
          ),
          child: Text(
            question.topic.name.toUpperCase(),
            style: const TextStyle(
              color: AddaColors.violet,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: _secondsLeft <= 5 ? AddaColors.coral : AddaColors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              '${_secondsLeft}s',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: _secondsLeft <= 5 ? AddaColors.coral : AddaColors.amber,
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
    );
  }

  Widget _buildQuestionCard(QuizQuestion question, bool isDark) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AddaSpacing.lg),
      child: Center(
        child: Text(
          question.question,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(int index, QuizQuestion question, bool isDark) {
    final isReveal = _state.phase == QuizRoundPhase.reveal;
    final isCorrect = index == question.correctIndex;
    final isSelected = _selectedOption == index;

    Color borderColor = Colors.transparent;
    Color bgColor = isDark ? AddaColors.surfaceDark : Colors.white;

    if (isReveal) {
      if (isCorrect) {
        borderColor = AddaColors.emerald;
        bgColor = AddaColors.emerald.withAlpha(40);
      } else if (isSelected) {
        borderColor = AddaColors.coral;
        bgColor = AddaColors.coral.withAlpha(40);
      }
    } else if (isSelected) {
      borderColor = AddaColors.violet;
      bgColor = AddaColors.violet.withAlpha(30);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AddaSpacing.sm),
      child: SurfaceCard(
        onTap: () => _chooseOption(index),
        borderColor: borderColor,
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AddaSpacing.md,
          vertical: AddaSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor != Colors.transparent
                      ? borderColor
                      : Colors.white24,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                String.fromCharCode(65 + index),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: AddaSpacing.md),
            Expanded(
              child: Text(
                question.options[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected || (isReveal && isCorrect)
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
            if (isReveal && isCorrect)
              const Icon(
                Icons.check_circle_rounded,
                color: AddaColors.emerald,
                size: 20,
              )
            else if (isReveal && isSelected)
              const Icon(
                Icons.cancel_rounded,
                color: AddaColors.coral,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreboard(bool isDark) {
    final sorted = _state.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sorted.map((entry) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: AddaRadius.radiusSm,
            ),
            child: Row(
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.value} pts',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AddaColors.amber,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
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
                Icons.emoji_events_rounded,
                color: AddaColors.amber,
                size: 64,
              ),
              const SizedBox(height: AddaSpacing.md),
              const Text(
                'Quiz Champion!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AddaSpacing.sm),
              Text(
                'Winner: ${result['winnerId']} (${result['winningScore']} pts)',
                style: const TextStyle(
                  fontSize: 16,
                  color: AddaColors.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AddaSpacing.xl),
              AppButton(
                text: 'Play Another Round',
                onPressed: () {
                  final user = ref.read(authProvider).valueOrNull;
                  final myId = user?.id ?? 'player_me';
                  setState(() {
                    _state = _engine.createInitialState([
                      myId,
                      'Rohan',
                      'Sneha',
                    ]);
                  });
                  _startTimer();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
