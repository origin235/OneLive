import 'dart:typed_data';

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

    test('online defaults to 0', () {
      final item = LiveRoomItem(
        roomId: '1',
        title: 't',
        cover: '',
        userName: 'u',
      );
      expect(item.online, 0);
    });
  });

  group('LiveAnchorItem', () {
    test('should create instance with required fields', () {
      final item = LiveAnchorItem(
        roomId: '789',
        avatar: 'https://example.com/avatar.jpg',
        userName: 'AnchorTest',
        liveStatus: true,
      );

      expect(item.roomId, '789');
      expect(item.userName, 'AnchorTest');
      expect(item.liveStatus, isTrue);
    });

    test('liveStatus false when not streaming', () {
      final item = LiveAnchorItem(
        roomId: '000',
        avatar: '',
        userName: 'OfflineAnchor',
        liveStatus: false,
      );

      expect(item.liveStatus, isFalse);
      expect(item.toString(), contains('"liveStatus":false'));
    });

    test('toString produces valid JSON', () {
      final item = LiveAnchorItem(
        roomId: '111',
        avatar: 'https://example.com/a.jpg',
        userName: 'JSONAnchor',
        liveStatus: true,
      );

      final str = item.toString();
      expect(str, contains('"roomId":"111"'));
      expect(str, contains('"userName":"JSONAnchor"'));
      expect(str, contains('"liveStatus":true'));
    });
  });

  group('LiveSearchRoomResult', () {
    test('should create with items list', () {
      final items = [
        LiveRoomItem(
          roomId: '1',
          title: 'Room 1',
          cover: '',
          userName: 'User1',
        ),
      ];
      final result = LiveSearchRoomResult(hasMore: true, items: items);

      expect(result.hasMore, isTrue);
      expect(result.items.length, 1);
    });

    test('empty items when no results', () {
      final result = LiveSearchRoomResult(hasMore: false, items: []);
      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
    });
  });

  group('LiveSearchAnchorResult', () {
    test('should create with items list', () {
      final items = [
        LiveAnchorItem(
          roomId: '2',
          avatar: '',
          userName: 'Anchor1',
          liveStatus: true,
        ),
      ];
      final result = LiveSearchAnchorResult(hasMore: false, items: items);

      expect(result.items.length, 1);
      expect(result.hasMore, isFalse);
    });
  });

  group('LivePlayUrl', () {
    test('should create with urls and optional headers', () {
      final url = LivePlayUrl(urls: ['https://example.com/stream.flv']);
      expect(url.urls, hasLength(1));
      expect(url.headers, isNull);
    });

    test('should accept headers', () {
      final url = LivePlayUrl(
        urls: ['https://example.com/stream.flv'],
        headers: {'Referer': 'https://example.com'},
      );
      expect(url.headers, containsPair('Referer', 'https://example.com'));
    });

    test('toString contains urls', () {
      final url = LivePlayUrl(
        urls: ['https://example.com/stream.flv'],
        headers: {'User-Agent': 'Test'},
      );
      expect(url.toString(), contains('stream.flv'));
    });
  });

  group('LiveRoomDetail', () {
    test('should create with all required fields', () {
      final detail = LiveRoomDetail(
        roomId: '123',
        title: 'Test Room',
        cover: 'https://example.com/cover.jpg',
        userName: 'Streamer',
        userAvatar: 'https://example.com/avatar.jpg',
        online: 999,
        status: true,
        url: 'https://example.com/room/123',
      );

      expect(detail.roomId, '123');
      expect(detail.title, 'Test Room');
      expect(detail.online, 999);
      expect(detail.status, isTrue);
      expect(detail.isRecord, isFalse);
    });

    test('optional fields can be null', () {
      final detail = LiveRoomDetail(
        roomId: '456',
        title: 'Minimal',
        cover: '',
        userName: 'U',
        userAvatar: '',
        online: 0,
        status: false,
        url: '',
      );

      expect(detail.introduction, isNull);
      expect(detail.notice, isNull);
      expect(detail.showTime, isNull);
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

    test('numberToColor handles 8-digit hex (with alpha)', () {
      final color = LiveMessageColor.numberToColor(0xFF123456);
      expect(color.r, 0x12);
      expect(color.g, 0x34);
      expect(color.b, 0x56);
    });

    test('numberToColor falls back to white for short hex', () {
      // 3-digit hex (after toRadixString) doesn't match 4/6/8 length checks
      final color = LiveMessageColor.numberToColor(0xFAB);
      expect(color.r, 255);
      expect(color.g, 255);
      expect(color.b, 255);
    });

    test('numberToColor falls back to white for invalid input', () {
      final color = LiveMessageColor.numberToColor(0xABCDEF12345);
      expect(color.r, 255);
      expect(color.g, 255);
      expect(color.b, 255);
    });

    test('toString returns hex format', () {
      final color = LiveMessageColor(18, 52, 86);
      expect(color.toString(), '#123456');
    });
  });

  group('LiveMessage', () {
    test('should create chat message', () {
      final msg = LiveMessage(
        type: LiveMessageType.chat,
        userName: 'User',
        message: 'Hello',
        color: LiveMessageColor.white,
      );

      expect(msg.type, LiveMessageType.chat);
      expect(msg.message, 'Hello');
    });

    test('should create gift message', () {
      final msg = LiveMessage(
        type: LiveMessageType.gift,
        userName: 'Donor',
        message: '送出火箭',
        color: LiveMessageColor(255, 0, 0),
      );

      expect(msg.type, LiveMessageType.gift);
    });

    test('toString contains type index', () {
      final msg = LiveMessage(
        type: LiveMessageType.superChat,
        userName: 'VIP',
        message: 'Nice!',
        color: LiveMessageColor.white,
      );
      expect(msg.toString(), contains('"type":3'));
    });
  });

  group('LiveSuperChatMessage', () {
    test('should create instance', () {
      final now = DateTime.now();
      final later = now.add(const Duration(hours: 1));
      final sc = LiveSuperChatMessage(
        userName: 'Rich User',
        face: 'https://face.example.com/1.jpg',
        message: 'Super chat!',
        price: 3000,
        startTime: now,
        endTime: later,
        backgroundColor: '#FF0000',
        backgroundBottomColor: '#CC0000',
      );

      expect(sc.userName, 'Rich User');
      expect(sc.price, 3000);
      expect(sc.endTime.isAfter(sc.startTime), isTrue);
    });
  });

  group('BinaryReader', () {
    test('should read byte', () {
      final reader = BinaryReader(Uint8List.fromList([0xAB, 0xCD, 0xEF]));
      expect(reader.readByte(), 0xAB);
      expect(reader.readByte(), 0xCD);
      expect(reader.readByte(), 0xEF);
    });

    test('should read int16 big endian', () {
      final reader = BinaryReader(Uint8List.fromList([0x12, 0x34, 0x56, 0x78]));
      expect(reader.readShort(), 0x1234);
      expect(reader.readShort(), 0x5678);
    });

    test('should read int16 little endian', () {
      final reader = BinaryReader(Uint8List.fromList([0x34, 0x12]));
      expect(reader.readShort(endian: Endian.little), 0x1234);
    });

    test('should read int32', () {
      final reader = BinaryReader(Uint8List.fromList([0x00, 0x00, 0x00, 0x2A]));
      expect(reader.readInt32(), 42);
    });

    test('should read bytes', () {
      final reader = BinaryReader(Uint8List.fromList([0x01, 0x02, 0x03, 0x04]));
      final bytes = reader.readBytes(3);
      expect(bytes, [0x01, 0x02, 0x03]);
      expect(reader.readByte(), 0x04);
    });

    test('length returns buffer length', () {
      final reader = BinaryReader(Uint8List.fromList([0x01, 0x02, 0x03]));
      expect(reader.length, 3);
    });
  });

  group('BinaryWriter', () {
    test('should write bytes', () {
      final writer = BinaryWriter([]);
      writer.writeBytes([0x01, 0x02, 0x03]);
      expect(writer.buffer, [0x01, 0x02, 0x03]);
      expect(writer.position, 3);
    });

    test('should write int16 big endian', () {
      final writer = BinaryWriter([]);
      writer.writeInt(0x1234, 2);
      expect(writer.buffer, [0x12, 0x34]);
    });

    test('should write int32', () {
      final writer = BinaryWriter([]);
      writer.writeInt(42, 4);
      expect(writer.length, 4);
    });

    test('should write int8', () {
      final writer = BinaryWriter([]);
      writer.writeInt(0xFF, 1);
      expect(writer.buffer, [0xFF]);
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

    test('default search returns empty results', () async {
      final site = LiveSite();
      site.id = 'test';
      site.name = 'Test';

      final rooms = await site.searchRooms('keyword');
      expect(rooms.items, isEmpty);

      final anchors = await site.searchAnchors('keyword');
      expect(anchors.items, isEmpty);
    });

    test('default getCategoryRooms returns empty', () async {
      final site = LiveSite();
      site.id = 'test';
      site.name = 'Test';

      final subCat = LiveSubCategory(id: '1', name: 'Sub', parentId: '0');
      final result = await site.getCategoryRooms(subCat);
      expect(result.items, isEmpty);
    });

    test('default getPlayUrls returns empty', () async {
      final site = LiveSite();
      site.id = 'test';
      site.name = 'Test';

      final detail = LiveRoomDetail(
        roomId: '123',
        title: '',
        cover: '',
        userName: '',
        userAvatar: '',
        online: 0,
        status: false,
        url: '',
      );
      final quality = LivePlayQuality(quality: 'auto', data: null);
      final url = await site.getPlayUrls(detail: detail, quality: quality);
      expect(url.urls, isEmpty);
    });

    test('default getRoomDetail returns empty detail', () async {
      final site = LiveSite();
      site.id = 'test';
      site.name = 'Test';

      final detail = await site.getRoomDetail(roomId: '123');
      expect(detail.roomId, '');
      expect(detail.status, isFalse);
    });
  });

  group('LiveCategory', () {
    test('should create with id, name and children', () {
      final cat = LiveCategory(id: '1', name: '游戏', children: []);
      expect(cat.id, '1');
      expect(cat.name, '游戏');
      expect(cat.children, isEmpty);
    });

    test('can have subcategories', () {
      final sub = LiveSubCategory(id: 'sub1', name: 'LOL', parentId: '1');
      final cat = LiveCategory(id: '1', name: '游戏', children: [sub]);
      expect(cat.children.length, 1);
      expect(cat.children.first.name, 'LOL');
    });
  });

  group('LivePlayQuality', () {
    test('should create with quality and data', () {
      final q = LivePlayQuality(quality: 'auto', data: null);
      expect(q.quality, 'auto');
      expect(q.sort, 0);
    });

    test('sort defaults to 0', () {
      final q = LivePlayQuality(quality: 'high', data: 'hd_data');
      expect(q.sort, 0);
    });
  });
}
