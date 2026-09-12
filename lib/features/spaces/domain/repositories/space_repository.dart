import '../models/space_model.dart';

abstract class SpaceRepository {
  Future<List<SpaceModel>> getSpaces();
  Future<SpaceModel?> getSpaceById(String id);
  Future<SpaceModel?> getSpaceByInviteCode(String code);
  Future<SpaceModel> createSpace({
    required String name,
    required SpaceType type,
    String? description,
    required String ownerId,
  });
  Future<SpaceModel> toggleFavorite(String id);
  Future<void> deleteSpace(String id);
}
