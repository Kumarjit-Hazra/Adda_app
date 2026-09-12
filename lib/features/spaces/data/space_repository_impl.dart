import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../../core/storage/storage_service.dart';
import '../domain/models/space_model.dart';
import '../domain/repositories/space_repository.dart';

class SpaceRepositoryImpl implements SpaceRepository {
  final StorageService _storage;
  static const String _spacesKey = 'adda_spaces_list';

  SpaceRepositoryImpl(this._storage);

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  List<SpaceModel> _getDefaultSpaces() {
    final now = DateTime.now();
    return [
      SpaceModel(
        id: 'spc_chai_adda',
        name: 'Chai Pe Adda ☕️',
        description: 'Late night adda with chai, gossip & card games',
        type: SpaceType.friends,
        inviteCode: 'CHAI29',
        ownerId: 'system',
        memberIds: ['system'],
        isFavorite: true,
        lastActiveAt: now,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      SpaceModel(
        id: 'spc_game_night',
        name: 'Weekend Gamers 🎮',
        description: 'Competitive 29, UNO clashes and bluff tournaments',
        type: SpaceType.gameNight,
        inviteCode: 'PLAY44',
        ownerId: 'system',
        memberIds: ['system'],
        isFavorite: true,
        lastActiveAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      SpaceModel(
        id: 'spc_brain_iacs',
        name: 'Puzzle Squad 🧩',
        description: 'Cooperative asymmetric mystery cases & math speed runs',
        type: SpaceType.study,
        inviteCode: 'BRAIN8',
        ownerId: 'system',
        memberIds: ['system'],
        isFavorite: false,
        lastActiveAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  @override
  Future<List<SpaceModel>> getSpaces() async {
    final raw = _storage.getString(_spacesKey);
    if (raw != null) {
      try {
        final list = json.decode(raw) as List<dynamic>;
        return list
            .map((e) => SpaceModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    final defaults = _getDefaultSpaces();
    await _saveSpaces(defaults);
    return defaults;
  }

  Future<void> _saveSpaces(List<SpaceModel> spaces) async {
    final raw = json.encode(spaces.map((s) => s.toMap()).toList());
    await _storage.setString(_spacesKey, raw);
  }

  @override
  Future<SpaceModel?> getSpaceById(String id) async {
    final spaces = await getSpaces();
    try {
      return spaces.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SpaceModel?> getSpaceByInviteCode(String code) async {
    final spaces = await getSpaces();
    final normalized = code.trim().toUpperCase();
    try {
      return spaces.firstWhere((s) => s.inviteCode.toUpperCase() == normalized);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SpaceModel> createSpace({
    required String name,
    required SpaceType type,
    String? description,
    required String ownerId,
  }) async {
    final spaces = await getSpaces();
    final newSpace = SpaceModel(
      id: 'spc_${const Uuid().v4().substring(0, 8)}',
      name: name.trim(),
      description: description?.trim() ?? '',
      type: type,
      inviteCode: _generateInviteCode(),
      ownerId: ownerId,
      memberIds: [ownerId],
      isFavorite: false,
      lastActiveAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final updated = [newSpace, ...spaces];
    await _saveSpaces(updated);
    return newSpace;
  }

  @override
  Future<SpaceModel> toggleFavorite(String id) async {
    final spaces = await getSpaces();
    final index = spaces.indexWhere((s) => s.id == id);
    if (index == -1) throw Exception('Space not found');

    final updated = spaces[index].copyWith(
      isFavorite: !spaces[index].isFavorite,
    );
    spaces[index] = updated;
    await _saveSpaces(spaces);
    return updated;
  }

  @override
  Future<void> deleteSpace(String id) async {
    final spaces = await getSpaces();
    spaces.removeWhere((s) => s.id == id);
    await _saveSpaces(spaces);
  }
}
