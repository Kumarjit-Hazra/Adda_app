import '../../activities/engine/activity_definition.dart';
import '../../activities/engine/activity_engine.dart';
import '../../activities/engine/player_action.dart';
import 'watch_together_models.dart';

class WatchTogetherEngine implements ActivityEngine<WatchTogetherState> {
  static const List<MediaTrack> defaultPlaylist = [
    MediaTrack(
      id: 'trk_1',
      title: 'Midnight Lofi Adda',
      artist: 'Kolkata Chillout Beats',
      durationSec: 180,
      mediaType: 'music',
      thumbnailUrl: '',
    ),
    MediaTrack(
      id: 'trk_2',
      title: 'Acoustic Sunset Serenade',
      artist: 'Adda Live Studio',
      durationSec: 210,
      mediaType: 'music',
      thumbnailUrl: '',
    ),
    MediaTrack(
      id: 'trk_3',
      title: 'Retro Bollywood Synth',
      artist: 'Disco Rhythms Collective',
      durationSec: 195,
      mediaType: 'music',
      thumbnailUrl: '',
    ),
    MediaTrack(
      id: 'trk_4',
      title: 'Rainy Night Rain & Tea Ambience',
      artist: 'Deep Focus Sounds',
      durationSec: 240,
      mediaType: 'music',
      thumbnailUrl: '',
    ),
  ];

  @override
  ActivityDefinition get definition => const ActivityDefinition(
    id: 'watch_together',
    title: 'Watch & Listen Together',
    description:
        'Synchronized room media player with sub-second playback sync, queue management, and party vibes.',
    category: ActivityCategory.party,
    minPlayers: 1,
    maxPlayers: 16,
    estimatedDuration: Duration(minutes: 30),
    rules:
        '1. Host controls master playback.\n2. Scrubbing and pausing syncs across all connected peers in real time.\n3. Anyone can queue upcoming tracks.',
  );

  @override
  WatchTogetherState createInitialState(List<String> playerIds) {
    final host = playerIds.isNotEmpty ? playerIds.first : 'host_1';
    return WatchTogetherState(
      version: 1,
      playerIds: playerIds,
      hostId: host,
      currentTrack: defaultPlaylist.first,
      isPlaying: true,
      playbackPositionSec: 0,
      playlist: defaultPlaylist,
      isFinished: false,
    );
  }

  @override
  bool validateAction(WatchTogetherState state, PlayerAction action) {
    if (state.isFinished) return false;
    if (!state.playerIds.contains(action.playerId)) return false;

    switch (action.type) {
      case 'play':
      case 'pause':
      case 'seek':
      case 'change_track':
      case 'add_to_queue':
        return true;
      default:
        return false;
    }
  }

  @override
  WatchTogetherState applyAction(
    WatchTogetherState state,
    PlayerAction action,
  ) {
    if (!validateAction(state, action)) return state;

    switch (action.type) {
      case 'play':
        return state.copyWith(version: state.version + 1, isPlaying: true);

      case 'pause':
        return state.copyWith(version: state.version + 1, isPlaying: false);

      case 'seek':
        final pos = (action.payload['positionSec'] as num?)?.toInt() ?? 0;
        return state.copyWith(
          version: state.version + 1,
          playbackPositionSec: pos.clamp(0, state.currentTrack.durationSec),
        );

      case 'change_track':
        final trackId = action.payload['trackId'] as String?;
        final track = state.playlist.firstWhere(
          (t) => t.id == trackId,
          orElse: () => state.currentTrack,
        );
        return state.copyWith(
          version: state.version + 1,
          currentTrack: track,
          playbackPositionSec: 0,
          isPlaying: true,
        );

      case 'add_to_queue':
        final newTrack = MediaTrack.fromMap(action.payload);
        return state.copyWith(
          version: state.version + 1,
          playlist: [...state.playlist, newTrack],
        );

      default:
        return state;
    }
  }

  @override
  bool isFinished(WatchTogetherState state) => state.isFinished;

  @override
  Map<String, dynamic> getResult(WatchTogetherState state) {
    return {
      'currentTrack': state.currentTrack.title,
      'position': state.playbackPositionSec,
      'queueLength': state.playlist.length,
    };
  }

  @override
  String serialize(WatchTogetherState state) => state.toJson();

  @override
  WatchTogetherState deserialize(String raw) =>
      WatchTogetherState.fromJson(raw);
}
