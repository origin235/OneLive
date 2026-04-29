import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_live_core/simple_live_core.dart';

import 'package:onelive/features/live/data/datasources/site_registry.dart';
import 'package:onelive/features/settings/presentation/providers/settings_providers.dart';

void main() {
  group('SiteRegistry', () {
    test('register and get', () {
      final site = LiveSite();
      site.id = 'test';
      site.name = 'Test Platform';

      SiteRegistry.register(site);
      final retrieved = SiteRegistry.get('test');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test');
      expect(retrieved.name, 'Test Platform');
    });

    test('get returns null for unknown platform', () {
      final result = SiteRegistry.get('unknown_platform');
      expect(result, isNull);
    });

    test('all returns all registered sites', () {
      final site1 = LiveSite();
      site1.id = 'platform_a';
      site1.name = 'A';

      final site2 = LiveSite();
      site2.id = 'platform_b';
      site2.name = 'B';

      SiteRegistry.register(site1);
      SiteRegistry.register(site2);

      expect(SiteRegistry.all.length, greaterThanOrEqualTo(2));
    });

    test('ids returns all registered ids', () {
      final ids = SiteRegistry.ids;
      expect(ids, isNotEmpty);
      expect(ids, contains('platform_a'));
    });
  });

  group('Settings Providers', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('themeMode defaults to system', () {
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('danmakuEnabled defaults to true', () {
      expect(container.read(danmakuEnabledProvider), isTrue);
    });

    test('danmakuOpacity defaults to 1.0', () {
      expect(container.read(danmakuOpacityProvider), 1.0);
    });

    test('danmakuFontSize defaults to 18.0', () {
      expect(container.read(danmakuFontSizeProvider), 18.0);
    });

    test('danmakuSpeed defaults to 150.0', () {
      expect(container.read(danmakuSpeedProvider), 150.0);
    });

    test('danmakuArea defaults to 0.8', () {
      expect(container.read(danmakuAreaProvider), 0.8);
    });

    test('qualityLevel defaults to 0', () {
      expect(container.read(qualityLevelProvider), 0);
    });
  });
}
