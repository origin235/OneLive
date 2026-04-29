import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_live_core/simple_live_core.dart';

import '../../../live/data/datasources/site_registry.dart';
import '../../../live/presentation/widgets/stream_grid.dart';
import '../providers/search_providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  late TabController _tabController;
  int _previousTabIndex = 0;

  final _platformIds = SiteRegistry.ids;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _platformIds.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == _previousTabIndex) return;
    _previousTabIndex = _tabController.index;
    // 切换 Tab 时如果有关键词则自动搜索当前平台
    _triggerSearchIfNeeded();
  }

  void _doSearch() {
    final keyword = _textController.text.trim();
    if (keyword.isEmpty) return;
    ref.read(searchKeywordProvider.notifier).state = keyword;
    _triggerSearchIfNeeded();
  }

  void _triggerSearchIfNeeded() {
    // invalidate 当前平台的搜索结果以确保重新加载
    final keyword = ref.read(searchKeywordProvider);
    if (keyword.isEmpty) return;
    final platform = _platformIds[_tabController.index];
    final mode = ref.read(searchModeProvider);
    if (mode == 0) {
      ref.invalidate(
        searchRoomsProvider((keyword: keyword, platform: platform)),
      );
    } else {
      ref.invalidate(
        searchAnchorsProvider((keyword: keyword, platform: platform)),
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(searchModeProvider);
    final keyword = ref.watch(searchKeywordProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索直播间或主播',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            prefixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                PopupMenuButton<int>(
                  initialValue: mode,
                  onSelected: (v) {
                    ref.read(searchModeProvider.notifier).state = v;
                    _doSearch();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0, child: Text('直播间')),
                    PopupMenuItem(value: 1, child: Text('主播')),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mode == 0 ? '直播间' : '主播',
                          style: Theme.of(context).textTheme.bodySmall),
                      const Icon(Icons.arrow_drop_down, size: 20),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ],
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _doSearch,
            ),
          ),
          onSubmitted: (_) => _doSearch(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabAlignment: TabAlignment.center,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 20),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _platformIds
              .map((id) {
                final site = SiteRegistry.get(id);
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_platformIcon(id), size: 20),
                      const SizedBox(width: 6),
                      Text(site?.name ?? id),
                    ],
                  ),
                );
              })
              .toList(),
        ),
      ),
      body: keyword.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('搜索直播', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('输入关键词，搜索四平台直播间和主播',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: _platformIds.map((platformId) {
                return _buildResultList(platformId: platformId, mode: mode);
              }).toList(),
            ),
    );
  }

  Widget _buildResultList({
    required String platformId,
    required int mode,
  }) {
    final keyword = ref.watch(searchKeywordProvider);

    if (mode == 0) {
      final resultAsync = ref.watch(
        searchRoomsProvider((keyword: keyword, platform: platformId)),
      );
      return resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (result) {
          if (result.items.isEmpty) {
            return const Center(child: Text('未找到相关直播间'));
          }
          return StreamGrid(items: result.items, platformId: platformId);
        },
      );
    } else {
      final resultAsync = ref.watch(
        searchAnchorsProvider((keyword: keyword, platform: platformId)),
      );
      return resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (result) {
          if (result.items.isEmpty) {
            return const Center(child: Text('未找到相关主播'));
          }
          return _AnchorList(items: result.items, platformId: platformId);
        },
      );
    }
  }

  static IconData _platformIcon(String id) {
    switch (id) {
      case 'bilibili':
        return Icons.play_circle_outline;
      case 'douyu':
        return Icons.water_drop_outlined;
      case 'huya':
        return Icons.pets;
      case 'douyin':
        return Icons.music_note_outlined;
      default:
        return Icons.live_tv;
    }
  }
}

/// 主播搜索结果列表
class _AnchorList extends StatelessWidget {
  final List<LiveAnchorItem> items;
  final String platformId;

  const _AnchorList({required this.items, required this.platformId});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: item.avatar.isNotEmpty
                ? NetworkImage(item.avatar)
                : null,
            child: item.avatar.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(item.userName),
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: item.liveStatus ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                item.liveStatus ? '直播中' : '未开播',
                style: TextStyle(
                  fontSize: 12,
                  color: item.liveStatus ? null : Colors.grey,
                ),
              ),
            ],
          ),
          onTap: () {
            if (item.roomId.isNotEmpty) {
              context.go('/player/$platformId/${item.roomId}');
            }
          },
        );
      },
    );
  }
}
