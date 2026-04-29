import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_live_core/simple_live_core.dart';

import '../../../live/data/datasources/site_registry.dart';

/// 已提交的搜索关键词（用户按回车或点击搜索后更新）
final searchKeywordProvider = StateProvider<String>((ref) => '');

/// 搜索模式：0=直播间，1=主播
final searchModeProvider = StateProvider<int>((ref) => 0);

/// 搜索直播间结果
final searchRoomsProvider = FutureProvider.autoDispose
    .family<LiveSearchRoomResult, ({String keyword, String platform})>(
  (ref, params) async {
    if (params.keyword.isEmpty) {
      return LiveSearchRoomResult(hasMore: false, items: []);
    }
    final site = SiteRegistry.get(params.platform);
    if (site == null) throw Exception('未知平台: ${params.platform}');
    return site.searchRooms(params.keyword);
  },
);

/// 搜索主播结果
final searchAnchorsProvider = FutureProvider.autoDispose
    .family<LiveSearchAnchorResult, ({String keyword, String platform})>(
  (ref, params) async {
    if (params.keyword.isEmpty) {
      return LiveSearchAnchorResult(hasMore: false, items: []);
    }
    final site = SiteRegistry.get(params.platform);
    if (site == null) throw Exception('未知平台: ${params.platform}');
    return site.searchAnchors(params.keyword);
  },
);
