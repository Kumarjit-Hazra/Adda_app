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
import 'draw_guess_engine.dart';
import 'draw_guess_models.dart';

class DrawGuessView extends ConsumerStatefulWidget {
  const DrawGuessView({super.key});

  @override
  ConsumerState<DrawGuessView> createState() => _DrawGuessViewState();
}

class _DrawGuessViewState extends ConsumerState<DrawGuessView> {
  final DrawGuessEngine _engine = DrawGuessEngine();
  late DrawGuessState _state;
  final TextEditingController _guessController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  Color _selectedColor = Colors.white;
  final double _selectedStrokeWidth = 4.0;

  final List<Color> _palette = [
    Colors.white,
    AddaColors.coral,
    AddaColors.amber,
    AddaColors.emerald,
    AddaColors.cyan,
    AddaColors.violet,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? 'player_me';
    _state = _engine.createInitialState([myId, 'Priya', 'Vikram']);
  }

  @override
  void dispose() {
    _guessController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _onPanUpdate(Offset localPosition, Size size, bool isStart) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    if (myId != _state.currentDrawerId) return;

    final normX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final normY = (localPosition.dy / size.height).clamp(0.0, 1.0);

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'draw_guess',
      type: 'add_point',
      payload: {
        'x': normX,
        'y': normY,
        'color': _selectedColor.toARGB32(),
        'strokeWidth': _selectedStrokeWidth,
        'isStart': isStart,
      },
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
  }

  void _clearCanvas() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    if (myId != _state.currentDrawerId) return;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'draw_guess',
      type: 'clear_canvas',
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playUiTap();
  }

  void _submitGuess() {
    final text = _guessController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'draw_guess',
      type: 'submit_guess',
      payload: {'guess': text},
      clientSequence: _state.version,
    );

    _guessController.clear();

    setState(() {
      _state = _engine.applyAction(_state, action);
    });

    if (text.toLowerCase() == _state.currentWord.toLowerCase()) {
      AudioService.playUiTap();
      HapticsService.mediumImpact();
    } else {
      HapticsService.lightTap();
    }

    _scrollToBottom();
  }

  void _nextRound() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'draw_guess',
      type: 'next_round',
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playUiTap();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final isDrawer = myId == _state.currentDrawerId;

    if (_state.isFinished) {
      final result = _engine.getResult(_state);
      return _buildFinishedView(isDark, result);
    }

    return Scaffold(
      backgroundColor: isDark ? AddaColors.bgDark : AddaColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDrawer, isDark),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AddaSpacing.md),
                child: _buildCanvas(isDrawer, isDark),
              ),
            ),
            if (isDrawer)
              _buildDrawerToolbar(isDark)
            else
              const SizedBox(height: AddaSpacing.xs),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(AddaSpacing.md),
                child: _buildGuessFeed(isDrawer, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDrawer, bool isDark) {
    return SurfaceCard(
      margin: const EdgeInsets.all(AddaSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AddaSpacing.md,
        vertical: AddaSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Round ${_state.currentRound}/${_state.totalRounds}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AddaColors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isDrawer
                    ? 'DRAW: ${_state.currentWord}'
                    : 'GUESS: ${_state.maskedWord}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          if (_state.roundSolved)
            ElevatedButton.icon(
              onPressed: _nextRound,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Next Round', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AddaColors.emerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCanvas(bool isDrawer, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFAFAFE),
            borderRadius: AddaRadius.radiusLg,
            border: Border.all(
              color: isDark
                  ? AddaColors.borderLuminousDark
                  : AddaColors.borderLuminousLight,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AddaRadius.radiusLg,
            child: GestureDetector(
              onPanStart: (details) =>
                  _onPanUpdate(details.localPosition, canvasSize, true),
              onPanUpdate: (details) =>
                  _onPanUpdate(details.localPosition, canvasSize, false),
              child: CustomPaint(
                size: canvasSize,
                painter: _CanvasPainter(points: _state.points),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AddaSpacing.md,
        vertical: AddaSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AddaColors.coral,
              size: 22,
            ),
            tooltip: 'Clear Canvas',
            onPressed: _clearCanvas,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _palette.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white30,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuessFeed(bool isDrawer, bool isDark) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AddaSpacing.sm),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              itemCount: _state.guesses.length,
              itemBuilder: (context, index) {
                final guess = _state.guesses[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '${guess.playerId}: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AddaColors.textSecondaryDark
                              : AddaColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        guess.text,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: guess.isCorrect
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: guess.isCorrect
                              ? AddaColors.emerald
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      if (guess.isCorrect) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AddaColors.emerald,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (!isDrawer && !_state.roundSolved)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _guessController,
                    decoration: const InputDecoration(
                      hintText: 'Type your guess...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                    onSubmitted: (_) => _submitGuess(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AddaColors.coral),
                  onPressed: _submitGuess,
                ),
              ],
            ),
        ],
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
                Icons.palette_rounded,
                color: AddaColors.coral,
                size: 60,
              ),
              const SizedBox(height: AddaSpacing.md),
              const Text(
                'Game Complete!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AddaSpacing.sm),
              Text(
                'Winner: ${result['winnerId']} (${result['highestScore']} pts)',
                style: const TextStyle(
                  fontSize: 16,
                  color: AddaColors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AddaSpacing.xl),
              AppButton(
                text: 'Play Again',
                onPressed: () {
                  final user = ref.read(authProvider).valueOrNull;
                  final myId = user?.id ?? 'player_me';
                  setState(() {
                    _state = _engine.createInitialState([
                      myId,
                      'Priya',
                      'Vikram',
                    ]);
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

class _CanvasPainter extends CustomPainter {
  final List<DrawPoint> points;

  _CanvasPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final paint = Paint()
        ..color = Color(p.color)
        ..strokeWidth = p.strokeWidth
        ..strokeCap = StrokeCap.round;

      final currentOffset = Offset(p.x * size.width, p.y * size.height);

      if (p.isStart || i == 0 || points[i - 1].isStart) {
        canvas.drawCircle(currentOffset, p.strokeWidth / 2, paint);
      } else {
        final prev = points[i - 1];
        final prevOffset = Offset(prev.x * size.width, prev.y * size.height);
        canvas.drawLine(prevOffset, currentOffset, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
