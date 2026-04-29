import 'package:drift/drift.dart';

import '../../../core/database/database.dart';

class FavoriteRepository {
  final AppDatabase _db;

  FavoriteRepository(this._db);

  // --- Favorites ---

  Future<void> addFavorite({
    required String platform,
    required String roomId,
    required String title,
    required String cover,
    required String userName,
  }) async {
    await _db.into(_db.favoriteRooms).insert(
          FavoriteRoomsCompanion.insert(
            platform: platform,
            roomId: roomId,
            title: title,
            cover: cover,
            userName: userName,
            addedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> removeFavorite(String platform, String roomId) async {
    final stmt = _db.delete(_db.favoriteRooms);
    stmt.where(
      (t) => t.platform.equals(platform) & t.roomId.equals(roomId),
    );
    await stmt.go();
  }

  Future<bool> isFavorite(String platform, String roomId) async {
    final query = _db.select(_db.favoriteRooms);
    query.where(
      (t) => t.platform.equals(platform) & t.roomId.equals(roomId),
    );
    final result = await query.getSingleOrNull();
    return result != null;
  }

  Stream<List<FavoriteRoom>> watchFavorites() {
    final query = _db.select(_db.favoriteRooms);
    query.orderBy([
      (t) => OrderingTerm(expression: t.addedAt, mode: OrderingMode.desc),
    ]);
    return query.watch();
  }

  // --- Watch History ---

  Future<void> recordWatch({
    required String platform,
    required String roomId,
    required String title,
    required String cover,
    required String userName,
  }) async {
    final stmt = _db.delete(_db.watchHistory);
    stmt.where(
      (t) => t.platform.equals(platform) & t.roomId.equals(roomId),
    );
    await stmt.go();
    await _db.into(_db.watchHistory).insert(
          WatchHistoryCompanion.insert(
            platform: platform,
            roomId: roomId,
            title: title,
            cover: cover,
            userName: userName,
            watchedAt: DateTime.now(),
          ),
        );
  }

  Stream<List<WatchHistoryData>> watchHistory() {
    final query = _db.select(_db.watchHistory);
    query.orderBy([
      (t) => OrderingTerm(expression: t.watchedAt, mode: OrderingMode.desc),
    ]);
    return query.watch();
  }
}
