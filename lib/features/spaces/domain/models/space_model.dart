import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

enum SpaceType {
  friends,
  couple,
  gameNight,
  study;

  String get displayName => switch (this) {
    SpaceType.friends => 'Friends Lounge',
    SpaceType.couple => 'Couple Corner',
    SpaceType.gameNight => 'Game Arena',
    SpaceType.study => 'Quiet Study',
  };

  IconData get icon => switch (this) {
    SpaceType.friends => Icons.groups_rounded,
    SpaceType.couple => Icons.favorite_rounded,
    SpaceType.gameNight => Icons.sports_esports_rounded,
    SpaceType.study => Icons.menu_book_rounded,
  };

  Color get color => switch (this) {
    SpaceType.friends => AddaColors.coral,
    SpaceType.couple => AddaColors.rose,
    SpaceType.gameNight => AddaColors.amber,
    SpaceType.study => AddaColors.cyan,
  };
}

class SpaceModel {
  final String id;
  final String name;
  final String description;
  final SpaceType type;
  final String inviteCode;
  final String ownerId;
  final List<String> memberIds;
  final bool isFavorite;
  final DateTime lastActiveAt;
  final DateTime createdAt;

  const SpaceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.inviteCode,
    required this.ownerId,
    required this.memberIds,
    this.isFavorite = false,
    required this.lastActiveAt,
    required this.createdAt,
  });

  SpaceModel copyWith({
    String? id,
    String? name,
    String? description,
    SpaceType? type,
    String? inviteCode,
    String? ownerId,
    List<String>? memberIds,
    bool? isFavorite,
    DateTime? lastActiveAt,
    DateTime? createdAt,
  }) {
    return SpaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      inviteCode: inviteCode ?? this.inviteCode,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      isFavorite: isFavorite ?? this.isFavorite,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'isFavorite': isFavorite,
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SpaceModel.fromMap(Map<String, dynamic> map) {
    return SpaceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      type: SpaceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SpaceType.friends,
      ),
      inviteCode: map['inviteCode'] as String,
      ownerId: map['ownerId'] as String,
      memberIds: (map['memberIds'] as List<dynamic>?)?.cast<String>() ?? [],
      isFavorite: map['isFavorite'] as bool? ?? false,
      lastActiveAt:
          DateTime.tryParse(map['lastActiveAt'] as String? ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SpaceModel.fromJson(String source) =>
      SpaceModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
