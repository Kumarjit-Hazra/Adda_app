import 'dart:convert';

class MediaTrack {
  final String id;
  final String title;
  final String artist;
  final int durationSec;
  final String mediaType; // 'music' or 'video'
  final String thumbnailUrl;

  const MediaTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationSec,
    required this.mediaType,
    required this.thumbnailUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'durationSec': durationSec,
    'mediaType': mediaType,
    'thumbnailUrl': thumbnailUrl,
  };

  factory MediaTrack.fromMap(Map<String, dynamic> map) => MediaTrack(
    id: map['id'] as String,
    title: map['title'] as String,
    artist: map['artist'] as String,
    durationSec: map['durationSec'] as int,
    mediaType: map['mediaType'] as String? ?? 'music',
    thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
  );
}

class WatchTogetherState {
  final int version;
  final List<String> playerIds;
  final String hostId;
  final MediaTrack currentTrack;
  final bool isPlaying;
  final int playbackPositionSec;
  final List<MediaTrack> playlist;
  final bool isFinished;

  const WatchTogetherState({
    required this.version,
    required this.playerIds,
    required this.hostId,
    required this.currentTrack,
    required this.isPlaying,
    required this.playbackPositionSec,
    required this.playlist,
    this.isFinished = false,
  });

  WatchTogetherState copyWith({
    int? version,
    List<String>? playerIds,
    String? hostId,
    MediaTrack? currentTrack,
    bool? isPlaying,
    int? playbackPositionSec,
    List<MediaTrack>? playlist,
    bool? isFinished,
  }) {
    return WatchTogetherState(
      version: version ?? this.version,
      playerIds: playerIds ?? this.playerIds,
      hostId: hostId ?? this.hostId,
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackPositionSec: playbackPositionSec ?? this.playbackPositionSec,
      playlist: playlist ?? this.playlist,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  Map<String, dynamic> toMap() => {
    'version': version,
    'playerIds': playerIds,
    'hostId': hostId,
    'currentTrack': currentTrack.toMap(),
    'isPlaying': isPlaying,
    'playbackPositionSec': playbackPositionSec,
    'playlist': playlist.map((t) => t.toMap()).toList(),
    'isFinished': isFinished,
  };

  factory WatchTogetherState.fromMap(Map<String, dynamic> map) =>
      WatchTogetherState(
        version: map['version'] as int,
        playerIds: (map['playerIds'] as List<dynamic>).cast<String>(),
        hostId: map['hostId'] as String,
        currentTrack: MediaTrack.fromMap(
          map['currentTrack'] as Map<String, dynamic>,
        ),
        isPlaying: map['isPlaying'] as bool? ?? false,
        playbackPositionSec: map['playbackPositionSec'] as int? ?? 0,
        playlist: (map['playlist'] as List<dynamic>)
            .map((t) => MediaTrack.fromMap(t as Map<String, dynamic>))
            .toList(),
        isFinished: map['isFinished'] as bool? ?? false,
      );

  String toJson() => json.encode(toMap());

  factory WatchTogetherState.fromJson(String source) =>
      WatchTogetherState.fromMap(json.decode(source) as Map<String, dynamic>);
}
