import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_live_core/simple_live_core.dart';

import '../../../favorites/presentation/providers/favorites_providers.dart';

class StreamGrid extends StatelessWidget {
  final List<LiveRoomItem> items;
  final String platformId;

  const StreamGrid({
    super.key,
    required this.items,
    required this.platformId,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          StreamCard(item: items[index], platformId: platformId),
    );
  }
}

class StreamCard extends ConsumerWidget {
  final LiveRoomItem item;
  final String platformId;

  const StreamCard({
    super.key,
    required this.item,
    required this.platformId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavAsync = ref.watch(
      isFavoriteProvider((platform: platformId, roomId: item.roomId)),
    );

    return GestureDetector(
      onTap: () => context.go('/player/$platformId/${item.roomId}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: item.cover.isNotEmpty
                      ? Image.network(
                          item.cover,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.live_tv, size: 48),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.live_tv, size: 48),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                          Text(
                            '${item.online}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: isFavAsync.maybeWhen(
                data: (isFav) => Material(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _toggleFavorite(ref, isFav),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_outline,
                        color: isFav ? Colors.red : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(WidgetRef ref, bool isCurrentlyFav) {
    final repo = ref.read(favoriteRepositoryProvider);
    if (isCurrentlyFav) {
      repo.removeFavorite(platformId, item.roomId);
    } else {
      repo.addFavorite(
        platform: platformId,
        roomId: item.roomId,
        title: item.title,
        cover: item.cover,
        userName: item.userName,
      );
    }
    ref.invalidate(
      isFavoriteProvider((platform: platformId, roomId: item.roomId)),
    );
  }
}
