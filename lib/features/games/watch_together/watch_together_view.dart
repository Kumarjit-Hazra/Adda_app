import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/surface_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../activities/engine/player_action.dart';
import 'watch_together_engine.dart';
import 'watch_together_models.dart';

class WatchTogetherView extends ConsumerStatefulWidget {
  const WatchTogetherView({super.key});

  @override
  ConsumerState<WatchTogetherView> createState() => _WatchTogetherViewState();
}

class _WatchTogetherViewState extends ConsumerState<WatchTogetherView> {
  final WatchTogetherEngine _engine = WatchTogetherEngine();
  late WatchTogetherState _state;
  Timer? _playbackTicker;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? 'player_me';
    _state = _engine.createInitialState([myId, 'Pooja', 'Sameer']);
    _startTicker();
  }

  @override
  void dispose() {
    _playbackTicker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _playbackTicker?.cancel();
    _playbackTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_state.isPlaying) {
        final currentPos = _state.playbackPositionSec;
        final maxDur = _state.currentTrack.durationSec;
        if (currentPos < maxDur) {
          setState(() {
            _state = _state.copyWith(playbackPositionSec: currentPos + 1);
          });
        } else {
          // Auto advance to next track
          _nextTrack();
        }
      }
    });
  }

  void _togglePlayPause() {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;
    final actionType = _state.isPlaying ? 'pause' : 'play';

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'watch_together',
      type: actionType,
      payload: {},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playUiTap();
    HapticsService.lightTap();
  }

  void _seek(double val) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'watch_together',
      type: 'seek',
      payload: {'positionSec': val.toInt()},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
  }

  void _selectTrack(String trackId) {
    final user = ref.read(authProvider).valueOrNull;
    final myId = user?.id ?? _state.playerIds.first;

    final action = PlayerAction(
      actionId: const Uuid().v4(),
      playerId: myId,
      activityId: 'watch_together',
      type: 'change_track',
      payload: {'trackId': trackId},
      clientSequence: _state.version,
    );

    setState(() {
      _state = _engine.applyAction(_state, action);
    });
    AudioService.playUiTap();
    HapticsService.mediumImpact();
  }

  void _nextTrack() {
    final currentIdx = _state.playlist.indexWhere(
      (t) => t.id == _state.currentTrack.id,
    );
    final nextIdx = (currentIdx + 1) % _state.playlist.length;
    _selectTrack(_state.playlist[nextIdx].id);
  }

  void _prevTrack() {
    final currentIdx = _state.playlist.indexWhere(
      (t) => t.id == _state.currentTrack.id,
    );
    final prevIdx =
        (currentIdx - 1 + _state.playlist.length) % _state.playlist.length;
    _selectTrack(_state.playlist[prevIdx].id);
  }

  String _formatDuration(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = _state.currentTrack;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF181024), const Color(0xFF090610)]
              : [const Color(0xFFFAF5FF), const Color(0xFFF3E8FF)],
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
              _buildTopSyncBar(),
              const SizedBox(height: AddaSpacing.md),
              Expanded(flex: 4, child: _buildVisualizerCard(track, isDark)),
              const SizedBox(height: AddaSpacing.md),
              _buildScrubber(track, isDark),
              _buildControls(),
              const SizedBox(height: AddaSpacing.md),
              Expanded(flex: 3, child: _buildPlaylist(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSyncBar() {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AddaSpacing.md,
        vertical: AddaSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.headset_rounded, color: AddaColors.violet, size: 18),
              SizedBox(width: 8),
              Text(
                'Watch & Listen Together',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AddaColors.emerald.withAlpha(30),
              borderRadius: AddaRadius.radiusSm,
            ),
            child: Row(
              children: const [
                Icon(Icons.bolt_rounded, color: AddaColors.emerald, size: 14),
                SizedBox(width: 2),
                Text(
                  'SYNCED',
                  style: TextStyle(
                    color: AddaColors.emerald,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizerCard(MediaTrack track, bool isDark) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AddaSpacing.lg),
      borderColor: AddaColors.violet.withAlpha(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AddaColors.violet.withAlpha(40),
              shape: BoxShape.circle,
              boxShadow: _state.isPlaying
                  ? [
                      BoxShadow(
                        color: AddaColors.violet.withAlpha(80),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _state.isPlaying
                  ? Icons.music_note_rounded
                  : Icons.music_off_rounded,
              color: AddaColors.violet,
              size: 48,
            ),
          ),
          const SizedBox(height: AddaSpacing.md),
          Text(
            track.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            track.artist,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AddaColors.textSecondaryDark
                  : AddaColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AddaSpacing.md),
          // Animated wave visualizer bars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(12, (index) {
              final heights = [
                14.0,
                24.0,
                32.0,
                18.0,
                40.0,
                28.0,
                16.0,
                36.0,
                22.0,
                30.0,
                20.0,
                12.0,
              ];
              final barH = _state.isPlaying ? heights[index] : 4.0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 4,
                height: barH,
                decoration: BoxDecoration(
                  color: AddaColors.violet,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildScrubber(MediaTrack track, bool isDark) {
    final maxSec = track.durationSec.toDouble();
    final currentSec = _state.playbackPositionSec
        .clamp(0, track.durationSec)
        .toDouble();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AddaColors.violet,
            inactiveTrackColor: Colors.white12,
            thumbColor: AddaColors.violet,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(value: currentSec, max: maxSec, onChanged: _seek),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AddaSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_state.playbackPositionSec),
                style: const TextStyle(fontSize: 11, color: Colors.white60),
              ),
              Text(
                _formatDuration(track.durationSec),
                style: const TextStyle(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.skip_previous_rounded,
            size: 32,
            color: Colors.white,
          ),
          onPressed: _prevTrack,
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AddaColors.violet,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AddaColors.violet,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(
            Icons.skip_next_rounded,
            size: 32,
            color: Colors.white,
          ),
          onPressed: _nextTrack,
        ),
      ],
    );
  }

  Widget _buildPlaylist(bool isDark) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AddaSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Shared Room Queue',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _state.playlist.length,
              itemBuilder: (context, index) {
                final item = _state.playlist[index];
                final isCurrent = item.id == _state.currentTrack.id;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AddaColors.violet.withAlpha(30)
                        : Colors.transparent,
                    borderRadius: AddaRadius.radiusSm,
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      isCurrent
                          ? Icons.volume_up_rounded
                          : Icons.music_note_rounded,
                      color: isCurrent ? AddaColors.violet : Colors.white38,
                      size: 20,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isCurrent ? Colors.white : Colors.white70,
                      ),
                    ),
                    subtitle: Text(
                      item.artist,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                    trailing: Text(
                      _formatDuration(item.durationSec),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                    onTap: () => _selectTrack(item.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
