import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/live_providers.dart';
import '../widgets/platform_filter_bar.dart';
import '../widgets/stream_grid.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlatform = ref.watch(selectedPlatformProvider);
    final roomsAsync = ref.watch(recommendRoomsProvider(selectedPlatform));

    return Scaffold(
      appBar: AppBar(
        title: const Text('OneLive'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          PlatformFilterBar(
            selectedId: selectedPlatform,
            onChanged: (id) =>
                ref.read(selectedPlatformProvider.notifier).state = id,
          ),
          Expanded(
            child: roomsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (result) => StreamGrid(
                items: result.items,
                platformId: selectedPlatform,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
