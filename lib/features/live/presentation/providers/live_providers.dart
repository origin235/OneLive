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

// --- 播放器相关 Provider ---

/// 播放参数 (platform + roomId)
class PlayerParams {
  final String platformId;
  final String roomId;
  const PlayerParams({required this.platformId, required this.roomId});

  @override
  bool operator ==(Object other) =>
      other is PlayerParams &&
      other.platformId == platformId &&
      other.roomId == roomId;

  @override
  int get hashCode => Object.hash(platformId, roomId);
}

/// 房间详情 Provider
final roomDetailProvider =
    FutureProvider.family<LiveRoomDetail, PlayerParams>((ref, params) async {
  final site = SiteRegistry.get(params.platformId);
  if (site == null) throw Exception('未知平台: ${params.platformId}');
  return site.getRoomDetail(roomId: params.roomId);
});

/// 播放清晰度列表 Provider (detail + platformId)
final playQualitiesProvider = FutureProvider.family<
    List<LivePlayQuality>,
    ({LiveRoomDetail detail, String platformId})>((ref, params) async {
  final site = SiteRegistry.get(params.platformId);
  if (site == null) throw Exception('未知平台: ${params.platformId}');
  return site.getPlayQualites(detail: params.detail);
});

/// 播放地址 Provider
final playUrlProvider =
    FutureProvider.family<LivePlayUrl, PlayerParams>((ref, params) async {
  final detail = await ref.read(roomDetailProvider(params).future);
  final qualities = await ref.read(
    playQualitiesProvider(
      (detail: detail, platformId: params.platformId),
    ).future,
  );
  if (qualities.isEmpty) throw Exception('无可用的播放清晰度');

  final site = SiteRegistry.get(params.platformId);
  if (site == null) throw Exception('未知平台');

  // 使用最高清晰度
  return site.getPlayUrls(detail: detail, quality: qualities.last);
});
