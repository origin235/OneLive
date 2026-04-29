import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../data/favorite_repository.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.watch(databaseProvider));
});

/// 收藏列表（响应式）
final favoritesProvider = StreamProvider<List<FavoriteRoom>>((ref) {
  return ref.watch(favoriteRepositoryProvider).watchFavorites();
});

/// 观看历史列表（响应式）
final watchHistoryProvider = StreamProvider<List<WatchHistoryData>>((ref) {
  return ref.watch(favoriteRepositoryProvider).watchHistory();
});

/// 检查指定房间是否已收藏
final isFavoriteProvider = FutureProvider.family<bool, ({String platform, String roomId})>(
  (ref, params) async {
    return ref.watch(favoriteRepositoryProvider).isFavorite(
          params.platform,
          params.roomId,
        );
  },
);
