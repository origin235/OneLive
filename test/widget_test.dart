import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_live_core/simple_live_core.dart';

import 'package:onelive/main.dart';
import 'package:onelive/features/live/data/datasources/site_registry.dart';
import 'package:onelive/features/settings/presentation/providers/settings_providers.dart';
import 'package:onelive/features/live/presentation/widgets/stream_grid.dart';
import 'package:onelive/features/live/presentation/widgets/platform_filter_bar.dart';
import 'package:onelive/features/settings/presentation/pages/settings_page.dart';

void main() {
  group('App smoke test', () {
    testWidgets('renders home page with OneLive title', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const OneLiveApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OneLive'), findsOneWidget);
    });
  });

  group('PlatformFilterBar', () {
    testWidgets('renders registered platforms as chips', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final site = LiveSite();
      site.id = 'testplatform';
      site.name = 'TestPlatform';
      SiteRegistry.register(site);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PlatformFilterBar(
                selectedId: 'testplatform',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TestPlatform'), findsOneWidget);
    });

    testWidgets('calls onChanged when chip tapped', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final site = LiveSite();
      site.id = 'test_a';
      site.name = 'TestA';
      SiteRegistry.register(site);

      final site2 = LiveSite();
      site2.id = 'test_b';
      site2.name = 'TestB';
      SiteRegistry.register(site2);

      String? selected;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PlatformFilterBar(
                selectedId: 'test_a',
                onChanged: (id) => selected = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('TestB'));
      expect(selected, 'test_b');
    });
  });

  group('StreamCard', () {
    testWidgets('renders room info', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final item = LiveRoomItem(
        roomId: 'test123',
        title: '测试直播标题',
        cover: '',
        userName: '测试主播',
        online: 1000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: StreamCard(
              item: item,
              platformId: 'test',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('测试直播标题'), findsOneWidget);
      expect(find.text('测试主播'), findsOneWidget);
    });
  });

  group('SettingsPage', () {
    testWidgets('renders key settings categories', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('主题模式'), findsOneWidget);
      expect(find.text('默认画质'), findsOneWidget);
      expect(find.text('弹幕开关'), findsOneWidget);
    });

    testWidgets('theme dialog opens on theme tap', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('主题模式'));
      await tester.pumpAndSettle();

      expect(find.text('选择主题'), findsOneWidget);
      expect(find.text('选择主题'), findsOneWidget);
      expect(find.text('浅色模式'), findsOneWidget);
      expect(find.text('深色模式'), findsOneWidget);
    });
  });
}
