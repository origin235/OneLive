import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/theme.dart';

/// SharedPreferences 实例提供者
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('需要在 ProviderScope 中覆写');
});

/// SharedPreferences 异步初始化
final sharedPreferencesAsyncProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// ============ 主题设置 ============

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final mode = prefs.getInt('themeMode') ?? 0;
  return ThemeMode.values[mode.clamp(0, 2)];
});

void setThemeMode(WidgetRef ref, ThemeMode mode) {
  ref.read(sharedPreferencesProvider).setInt('themeMode', mode.index);
  ref.read(themeModeProvider.notifier).state = mode;
}

// ============ 弹幕设置 ============

final danmakuEnabledProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('danmakuEnabled') ?? true;
});

void setDanmakuEnabled(WidgetRef ref, bool enabled) {
  ref.read(sharedPreferencesProvider).setBool('danmakuEnabled', enabled);
  ref.read(danmakuEnabledProvider.notifier).state = enabled;
}

final danmakuOpacityProvider = StateProvider<double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getDouble('danmakuOpacity') ?? 1.0;
});

void setDanmakuOpacity(WidgetRef ref, double opacity) {
  ref.read(sharedPreferencesProvider).setDouble('danmakuOpacity', opacity);
  ref.read(danmakuOpacityProvider.notifier).state = opacity;
}

final danmakuFontSizeProvider = StateProvider<double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getDouble('danmakuFontSize') ?? 18.0;
});

void setDanmakuFontSize(WidgetRef ref, double size) {
  ref.read(sharedPreferencesProvider).setDouble('danmakuFontSize', size);
  ref.read(danmakuFontSizeProvider.notifier).state = size;
}

final danmakuSpeedProvider = StateProvider<double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getDouble('danmakuSpeed') ?? 150.0;
});

void setDanmakuSpeed(WidgetRef ref, double speed) {
  ref.read(sharedPreferencesProvider).setDouble('danmakuSpeed', speed);
  ref.read(danmakuSpeedProvider.notifier).state = speed;
}

final danmakuAreaProvider = StateProvider<double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getDouble('danmakuArea') ?? 0.8;
});

void setDanmakuArea(WidgetRef ref, double area) {
  ref.read(sharedPreferencesProvider).setDouble('danmakuArea', area);
  ref.read(danmakuAreaProvider.notifier).state = area;
}

// ============ 播放设置 ============

final qualityLevelProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getInt('qualityLevel') ?? 0;
});

void setQualityLevel(WidgetRef ref, int level) {
  ref.read(sharedPreferencesProvider).setInt('qualityLevel', level);
  ref.read(qualityLevelProvider.notifier).state = level;
}

// ============ 平台启禁 ============

final platformEnabledProvider = StateProvider.family<bool, String>((ref, platformId) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('platform_$platformId') ?? true;
});

void setPlatformEnabled(WidgetRef ref, String platformId, bool enabled) {
  ref.read(sharedPreferencesProvider).setBool('platform_$platformId', enabled);
  ref.invalidate(platformEnabledProvider(platformId));
}
