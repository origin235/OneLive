import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_providers.dart';
import '../../data/datasources/site_registry.dart';

class PlatformFilterBar extends ConsumerWidget {
  final String selectedId;
  final ValueChanged<String> onChanged;

  const PlatformFilterBar({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sites = SiteRegistry.all
        .where((s) => ref.watch(platformEnabledProvider(s.id)))
        .toList();

    if (sites.isEmpty) {
      return const SizedBox(height: 48);
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final site = sites[index];
          final isSelected = site.id == selectedId;
          return FilterChip(
            label: Text(site.name),
            selected: isSelected,
            onSelected: (_) => onChanged(site.id),
          );
        },
      ),
    );
  }
}
