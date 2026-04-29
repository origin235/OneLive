import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simple_live_core/simple_live_core.dart';

import '../../../live/data/datasources/site_registry.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _section('外观', context),
          _ThemeModeTile(),
          const Divider(indent: 72, endIndent: 16),
          _section('播放', context),
          _QualityTile(),
          const Divider(indent: 72, endIndent: 16),
          _section('弹幕', context),
          _DanmakuEnableTile(),
          _DanmakuOpacityTile(),
          _DanmakuFontSizeTile(),
          _DanmakuSpeedTile(),
          _DanmakuAreaTile(),
          const Divider(indent: 72, endIndent: 16),
          _section('平台', context),
          ...SiteRegistry.all.map((site) => _PlatformEnableTile(site: site)),
          const Divider(indent: 72, endIndent: 16),
          _section('关于', context),
          const _AboutTile(),
        ],
      ),
    );
  }

  Widget _section(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// 主题模式设置
class _ThemeModeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final labels = ['跟随系统', '浅色模式', '深色模式'];
    final icons = [Icons.brightness_auto, Icons.light_mode, Icons.dark_mode];

    return ListTile(
      leading: Icon(icons[themeMode.index]),
      title: const Text('主题模式'),
      subtitle: Text(labels[themeMode.index]),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, ref),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择主题'),
        children: ThemeMode.values.map((mode) {
          final labels = ['跟随系统', '浅色模式', '深色模式'];
          final icons = [Icons.brightness_auto, Icons.light_mode, Icons.dark_mode];
          return RadioListTile<ThemeMode>(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[mode.index], size: 20),
                const SizedBox(width: 12),
                Text(labels[mode.index]),
              ],
            ),
            value: mode,
            groupValue: ref.watch(themeModeProvider),
            onChanged: (v) {
              if (v != null) setThemeMode(ref, v);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}

/// 默认画质
class _QualityTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(qualityLevelProvider);
    final labels = ['自动', '流畅', '高清', '超清', '蓝光'];

    return ListTile(
      leading: const Icon(Icons.hd_outlined),
      title: const Text('默认画质'),
      subtitle: Text(labels[level.clamp(0, labels.length - 1)]),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showQualityDialog(context, ref),
    );
  }

  void _showQualityDialog(BuildContext context, WidgetRef ref) {
    final labels = ['自动', '流畅', '高清', '超清', '蓝光'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('默认画质'),
        children: List.generate(labels.length, (i) {
          return RadioListTile<int>(
            title: Text(labels[i]),
            value: i,
            groupValue: ref.watch(qualityLevelProvider),
            onChanged: (v) {
              if (v != null) setQualityLevel(ref, v);
              Navigator.pop(ctx);
            },
          );
        }),
      ),
    );
  }
}

/// 弹幕开关
class _DanmakuEnableTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(danmakuEnabledProvider);
    return SwitchListTile(
      secondary: const Icon(Icons.subtitles_outlined),
      title: const Text('弹幕开关'),
      value: enabled,
      onChanged: (v) => setDanmakuEnabled(ref, v),
    );
  }
}

/// 弹幕不透明度
class _DanmakuOpacityTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opacity = ref.watch(danmakuOpacityProvider);
    return ListTile(
      leading: const Icon(Icons.opacity),
      title: const Text('弹幕不透明度'),
      subtitle: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Theme.of(context).colorScheme.primary,
          thumbColor: Theme.of(context).colorScheme.primary,
        ),
        child: Slider(
          value: opacity,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          label: '${(opacity * 100).toInt()}%',
          onChanged: (v) => setDanmakuOpacity(ref, v),
        ),
      ),
    );
  }
}

/// 弹幕字体大小
class _DanmakuFontSizeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(danmakuFontSizeProvider);
    return ListTile(
      leading: const Icon(Icons.format_size),
      title: const Text('弹幕字体大小'),
      subtitle: Slider(
        value: size,
        min: 10,
        max: 40,
        divisions: 15,
        label: '${size.toInt()}px',
        onChanged: (v) => setDanmakuFontSize(ref, v),
      ),
    );
  }
}

/// 弹幕速度
class _DanmakuSpeedTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(danmakuSpeedProvider);
    return ListTile(
      leading: const Icon(Icons.speed),
      title: const Text('弹幕速度'),
      subtitle: Slider(
        value: speed,
        min: 60,
        max: 300,
        divisions: 12,
        label: '${speed.toInt()} px/s',
        onChanged: (v) => setDanmakuSpeed(ref, v),
      ),
    );
  }
}

/// 弹幕显示区域
class _DanmakuAreaTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(danmakuAreaProvider);
    return ListTile(
      leading: const Icon(Icons.view_stream),
      title: const Text('弹幕显示区域'),
      subtitle: Slider(
        value: area,
        min: 0.1,
        max: 1.0,
        divisions: 9,
        label: '${(area * 100).toInt()}%',
        onChanged: (v) => setDanmakuArea(ref, v),
      ),
    );
  }
}

/// 平台启禁
class _PlatformEnableTile extends ConsumerWidget {
  final LiveSite site;
  const _PlatformEnableTile({required this.site});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(platformEnabledProvider(site.id));
    return SwitchListTile(
      secondary: Icon(
        _platformIcon(site.id),
        color: enabled ? null : Colors.grey,
      ),
      title: Text(site.name),
      value: enabled,
      onChanged: (v) => setPlatformEnabled(ref, site.id, v),
    );
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

/// 关于
class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
            : '0.1.0 (开发中)';
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('版本'),
              subtitle: Text(version),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('技术栈'),
              subtitle: const Text('Flutter/Dart · Riverpod · media_kit · Drift'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('免责声明'),
              subtitle: const Text('本应用仅供学习交流，直播内容版权归属各平台'),
            ),
          ],
        );
      },
    );
  }
}
