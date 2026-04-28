import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_live_core/simple_live_core.dart';

import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'features/live/data/datasources/site_registry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 注册所有直播平台
  SiteRegistry.register(BiliBiliSite());

  runApp(
    const ProviderScope(
      child: OneLiveApp(),
    ),
  );
}

class OneLiveApp extends ConsumerWidget {
  const OneLiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'OneLive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localeListResolutionCallback: (locales, supportedLocales) {
        // 优先中文
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
