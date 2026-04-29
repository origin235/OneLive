import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:window_manager/window_manager.dart';

import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'features/live/data/datasources/site_registry.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows 窗口管理
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getInt('window_x');
    final savedY = prefs.getInt('window_y');
    final savedW = prefs.getInt('window_w');
    final savedH = prefs.getInt('window_h');

    final options = WindowOptions(
      size: (savedW != null && savedH != null)
          ? Size(savedW.toDouble(), savedH.toDouble())
          : const Size(1280, 720),
      center: savedW == null,
      minimumSize: const Size(800, 480),
      title: 'OneLive',
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
      if (savedX != null && savedY != null) {
        await windowManager.setPosition(Offset(savedX.toDouble(), savedY.toDouble()));
      }
    });

    // 窗口关闭前保存位置和大小
    windowManager.addListener(_WindowStateSaver());
  }

  // 初始化 SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 注册所有直播平台
  SiteRegistry.register(BiliBiliSite());
  SiteRegistry.register(DouyuSite());
  SiteRegistry.register(HuyaSite());
  SiteRegistry.register(DouyinSite());

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const OneLiveApp(),
    ),
  );
}

/// 监听窗口变化并保存位置/大小
class _WindowStateSaver extends WindowListener {
  _WindowStateSaver();

  @override
  void onWindowResized() async {
    final size = await windowManager.getSize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('window_w', size.width.toInt());
    await prefs.setInt('window_h', size.height.toInt());
  }

  @override
  void onWindowMoved() async {
    final pos = await windowManager.getPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('window_x', pos.dx.toInt());
    await prefs.setInt('window_y', pos.dy.toInt());
  }
}

class OneLiveApp extends ConsumerWidget {
  const OneLiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'OneLive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      localeListResolutionCallback: (locales, supportedLocales) {
        for (final locale in locales ?? []) {
          if (locale.languageCode == 'zh') return locale;
        }
        return null;
      },
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
