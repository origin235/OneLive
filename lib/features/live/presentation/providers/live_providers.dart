import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_live_core/simple_live_core.dart';

import '../../data/datasources/site_registry.dart';

/// 推荐直播列表 Provider
final recommendRoomsProvider =
    FutureProvider.family<LiveCategoryResult, String>((ref, platformId) async {
  final site = SiteRegistry.get(platformId);
  if (site == null) {
    return LiveCategoryResult(hasMore: false, items: []);
  }
  return site.getRecommendRooms(page: 1);
});

/// 当前选中的平台 ID
final selectedPlatformProvider = StateProvider<String>((ref) {
  final sites = SiteRegistry.all;
  return sites.isNotEmpty ? sites.first.id : '';
});

/// 所有已注册的平台 ID 列表
final platformIdsProvider = Provider<List<String>>((ref) {
  return SiteRegistry.ids;
});
