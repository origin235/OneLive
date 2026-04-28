import 'package:test/test.dart';
import 'package:simple_live_core/simple_live_core.dart';

void main() {
  group('LiveRoomItem', () {
    test('should create instance with required fields', () {
      final item = LiveRoomItem(
        roomId: '123',
        title: '测试直播间',
        cover: 'https://example.com/cover.jpg',
        userName: '测试主播',
      );

      expect(item.roomId, '123');
      expect(item.title, '测试直播间');
      expect(item.online, 0);
    });

    test('toString should return valid JSON', () {
      final item = LiveRoomItem(
        roomId: '456',
        title: 'JSON Test',
        cover: '',
        userName: 'Tester',
        online: 100,
      );

      final str = item.toString();
      expect(str, contains('"roomId":"456"'));
      expect(str, contains('"online":100'));
    });
  });

  group('LiveMessageColor', () {
    test('white is 255,255,255', () {
      expect(LiveMessageColor.white.r, 255);
      expect(LiveMessageColor.white.g, 255);
      expect(LiveMessageColor.white.b, 255);
    });

    test('numberToColor handles 6-digit hex', () {
      final color = LiveMessageColor.numberToColor(0xFF5733);
      expect(color.r, 255);
      expect(color.g, 87);
      expect(color.b, 51);
    });
  });

  group('LiveSite', () {
    test('default implementation returns empty results', () async {
      final site = LiveSite();
      site.id = 'test';
      site.name = 'Test';

      expect(site.id, 'test');
      expect(site.name, 'Test');

      final categories = await site.getCategores();
      expect(categories, isEmpty);

      final rooms = await site.getRecommendRooms();
      expect(rooms.items, isEmpty);
    });
  });
}
