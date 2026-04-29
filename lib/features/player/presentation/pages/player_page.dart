import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:simple_live_core/simple_live_core.dart';

import '../../../danmaku/data/danmaku_providers.dart';
import '../../../danmaku/presentation/widgets/danmaku_overlay.dart';
import '../../../live/presentation/providers/live_providers.dart';

class PlayerPage extends ConsumerStatefulWidget {
  final String platform;
  final String roomId;

  const PlayerPage({
    super.key,
    required this.platform,
    required this.roomId,
  });

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  late final Player _player;
  late final VideoController _videoController;
  bool _playbackStarted = false;
  LiveDanmaku? _danmaku;
  bool _danmakuReady = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
  }

  @override
  void dispose() {
    _danmaku?.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startPlayback() async {
    final params = PlayerParams(
      platformId: widget.platform,
      roomId: widget.roomId,
    );

    try {
      final playUrl = await ref.read(playUrlProvider(params).future);
      if (!mounted) return;

      if (playUrl.urls.isEmpty) throw Exception('无可用的播放地址');

      await _player.open(
        Media(playUrl.urls.first, httpHeaders: playUrl.headers ?? {}),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = PlayerParams(
      platformId: widget.platform,
      roomId: widget.roomId,
    );
    final detailAsync = ref.watch(roomDetailProvider(params));
    final playUrlAsync = ref.watch(playUrlProvider(params));

    // 播放地址就绪后启动播放
    if (!_playbackStarted && playUrlAsync.hasValue) {
      _playbackStarted = true;
      Future.microtask(_startPlayback);
    }

    // 房间详情就绪后创建弹幕客户端
    if (!_danmakuReady && detailAsync.hasValue) {
      _danmakuReady = true;
      _danmaku = DanmakuFactory.create(widget.platform);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 视频播放器
          Video(
            controller: _videoController,
            fit: BoxFit.contain,
          ),
          // 弹幕覆盖层
          if (_danmaku != null && detailAsync.hasValue)
            DanmakuOverlay(
              danmaku: _danmaku,
              danmakuData: detailAsync.value!.danmakuData,
              enabled: true,
            ),
          // 加载指示
          if (playUrlAsync.isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          // 错误提示
          if (playUrlAsync.hasError)
            Center(
              child: Text(
                '播放地址获取失败: ${playUrlAsync.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          // 顶部信息栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context, detailAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AsyncValue<dynamic> detailAsync,
  ) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: Colors.black54,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: detailAsync.maybeWhen(
              data: (detail) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    detail.title,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${detail.userName}  ·  ${_formatOnline(detail.online)}人在看',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              orElse: () => const Text(
                '加载中…',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatOnline(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }
}
