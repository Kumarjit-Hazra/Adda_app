import 'dart:convert';

/// Strongly-typed preferences for theme, audio, and tactile response.
class UserPreferences {
  final String themeMode; // 'dark' | 'light' | 'system'
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool reducedMotion;

  const UserPreferences({
    this.themeMode = 'dark',
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
  });

  UserPreferences copyWith({
    String? themeMode,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? reducedMotion,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
      'reducedMotion': reducedMotion,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      themeMode: map['themeMode'] as String? ?? 'dark',
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      hapticsEnabled: map['hapticsEnabled'] as bool? ?? true,
      reducedMotion: map['reducedMotion'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferences &&
        other.themeMode == themeMode &&
        other.soundEnabled == soundEnabled &&
        other.hapticsEnabled == hapticsEnabled &&
        other.reducedMotion == reducedMotion;
  }

  @override
  int get hashCode =>
      Object.hash(themeMode, soundEnabled, hapticsEnabled, reducedMotion);
}

/// Core identity model representing either a guest or registered user in ADDA.
class UserProfile {
  final String id;
  final String name;
  final bool isGuest;
  final String? avatarUrl;
  final String? avatarSeed;
  final String? statusMessage;
  final UserPreferences preferences;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.isGuest = true,
    this.avatarUrl,
    this.avatarSeed,
    this.statusMessage,
    this.preferences = const UserPreferences(),
    required this.createdAt,
  });

  /// Alias getters conforming to ADDA identity specification
  String get guestUuid => id;
  String get displayName => name;

  UserProfile copyWith({
    String? id,
    String? name,
    bool? isGuest,
    String? avatarUrl,
    String? avatarSeed,
    String? statusMessage,
    UserPreferences? preferences,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      isGuest: isGuest ?? this.isGuest,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      statusMessage: statusMessage ?? this.statusMessage,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isGuest': isGuest,
      'avatarUrl': avatarUrl,
      'avatarSeed': avatarSeed,
      'statusMessage': statusMessage,
      'preferences': preferences.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      isGuest: map['isGuest'] as bool? ?? true,
      avatarUrl: map['avatarUrl'] as String?,
      avatarSeed: map['avatarSeed'] as String?,
      statusMessage: map['statusMessage'] as String?,
      preferences: map['preferences'] is Map<String, dynamic>
          ? UserPreferences.fromMap(map['preferences'] as Map<String, dynamic>)
          : const UserPreferences(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.avatarSeed == avatarSeed &&
        other.preferences == preferences;
  }

  @override
  int get hashCode => Object.hash(id, name, avatarSeed, preferences);
}
