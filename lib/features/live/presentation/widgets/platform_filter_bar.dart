import 'package:flutter/material.dart';
import '../../data/datasources/site_registry.dart';

class PlatformFilterBar extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onChanged;

  const PlatformFilterBar({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sites = SiteRegistry.all;

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
