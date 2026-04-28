import 'package:flutter/material.dart';

class PlayerPage extends StatelessWidget {
  final String platform;
  final String roomId;

  const PlayerPage({
    super.key,
    required this.platform,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('播放中 — $platform'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, size: 64),
            const SizedBox(height: 16),
            Text('直播间: $roomId'),
            const SizedBox(height: 8),
            Text('平台: $platform'),
            const SizedBox(height: 24),
            const Text('播放器将在阶段 3 接入 media_kit'),
          ],
        ),
      ),
    );
  }
}
