import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../common/binary_writer.dart';
import '../common/web_socket_util.dart';
import '../interface/live_danmaku.dart';
import '../model/live_message.dart';
import 'package:simple_live_core/simple_live_core.dart';

class DouyuDanmaku implements LiveDanmaku {
  @override
  int heartbeatTime = 45 * 1000;

  @override
  Function(LiveMessage msg)? onMessage;
  @override
  Function(String msg)? onClose;
  @override
  Function()? onReady;

  String serverUrl = 'wss://danmuproxy.douyu.com:8506';
  WebSocketUtil? webScoketUtils;

  @override
  Future start(dynamic args) async {
    webScoketUtils = WebSocketUtil(
      url: serverUrl,
      heartBeatTime: heartbeatTime,
      onMessage: (e) {
        decodeMessage(e);
      },
      onReady: () {
        onReady?.call();
        joinRoom(args);
      },
      onHeartBeat: () {
        heartbeat();
      },
      onReconnect: () {
        onClose?.call('与服务器断开连接，正在尝试重连');
      },
      onClose: (e) {
        onClose?.call('服务器连接失败$e');
      },
    );
    webScoketUtils?.connect();
  }

  void joinRoom(roomId) {
    webScoketUtils
        ?.sendMessage(serializeDouyu('type@=loginreq/roomid@=$roomId/'));
    webScoketUtils?.sendMessage(
        serializeDouyu('type@=joingroup/rid@=$roomId/gid@=-9999/'));
  }

  @override
  void heartbeat() {
    final data = serializeDouyu('type@=mrkl/');
    webScoketUtils?.sendMessage(data);
  }

  @override
  Future stop() async {
    onMessage = null;
    onClose = null;
    webScoketUtils?.close();
  }

  void decodeMessage(List<int> data) {
    try {
      final result = deserializeDouyu(data);
      if (result == null) return;
      final jsonData = sttToJObject(result);
      final type = jsonData['type']?.toString();
      if (type == 'chatmsg') {
        if (jsonData['dms'] == null) return;
        final col = int.tryParse(jsonData['col'].toString()) ?? 0;
        final liveMsg = LiveMessage(
          type: LiveMessageType.chat,
          userName: jsonData['nn'].toString(),
          message: jsonData['txt'].toString(),
          color: getColor(col),
        );
        onMessage?.call(liveMsg);
      }
    } catch (e) {
      CoreLog.error(e);
    }
  }

  List<int> serializeDouyu(String body) {
    try {
      const clientSendToServer = 689;
      const encrypted = 0;
      const reserved = 0;

      final buffer = utf8.encode(body);
      final writer = BinaryWriter([]);
      writer.writeInt(4 + 4 + body.length + 1, 4, endian: Endian.little);
      writer.writeInt(4 + 4 + body.length + 1, 4, endian: Endian.little);
      writer.writeInt(clientSendToServer, 2, endian: Endian.little);
      writer.writeInt(encrypted, 1, endian: Endian.little);
      writer.writeInt(reserved, 1, endian: Endian.little);
      writer.writeBytes(buffer);
      writer.writeInt(0, 1, endian: Endian.little);
      return writer.buffer;
    } catch (e) {
      CoreLog.error(e);
      return [];
    }
  }

  String? deserializeDouyu(List<int> buffer) {
    try {
      final reader = BinaryReader(Uint8List.fromList(buffer));
      final fullMsgLength = reader.readInt32(endian: Endian.little);
      reader.readInt32(endian: Endian.little); // fullMsgLength2
      final bodyLength = fullMsgLength - 9;
      reader.readShort(endian: Endian.little); // packType
      reader.readByte(endian: Endian.little); // encrypted
      reader.readByte(endian: Endian.little); // reserved
      final bytes = reader.readBytes(bodyLength);
      reader.readByte(endian: Endian.little); // 固定为0
      return utf8.decode(bytes);
    } catch (e) {
      CoreLog.error(e);
      return null;
    }
  }

  dynamic sttToJObject(String str) {
    if (str.contains('//')) {
      final result = [];
      for (final field in str.split('//')) {
        if (field.isEmpty) continue;
        result.add(sttToJObject(field));
      }
      return result;
    }
    if (str.contains('@=')) {
      final result = {};
      for (final field in str.split('/')) {
        if (field.isEmpty) continue;
        final tokens = field.split('@=');
        final k = tokens[0];
        final v = unscapeSlashAt(tokens[1]);
        result[k] = sttToJObject(v);
      }
      return result;
    } else if (str.contains('@A=')) {
      return sttToJObject(unscapeSlashAt(str));
    } else {
      return unscapeSlashAt(str);
    }
  }

  String unscapeSlashAt(String str) {
    return str.replaceAll('@S', '/').replaceAll('@A', '@');
  }

  LiveMessageColor getColor(int type) {
    switch (type) {
      case 1:
        return LiveMessageColor(255, 0, 0);
      case 2:
        return LiveMessageColor(30, 135, 240);
      case 3:
        return LiveMessageColor(122, 200, 75);
      case 4:
        return LiveMessageColor(255, 127, 0);
      case 5:
        return LiveMessageColor(155, 57, 244);
      case 6:
        return LiveMessageColor(255, 105, 180);
      default:
        return LiveMessageColor.white;
    }
  }
}
