import 'dart:convert';

class UserProfile {
  final String id;
  final String name;
  final bool isGuest;
  final String? avatarUrl;
  final String? statusMessage;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.isGuest = true,
    this.avatarUrl,
    this.statusMessage,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    bool? isGuest,
    String? avatarUrl,
    String? statusMessage,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      isGuest: isGuest ?? this.isGuest,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isGuest': isGuest,
      'avatarUrl': avatarUrl,
      'statusMessage': statusMessage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      isGuest: map['isGuest'] as bool? ?? true,
      avatarUrl: map['avatarUrl'] as String?,
      statusMessage: map['statusMessage'] as String?,
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
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
