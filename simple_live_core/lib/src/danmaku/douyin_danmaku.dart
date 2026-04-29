import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';

import '../scripts/douyin_sign.dart';
import '../platform/douyin_site.dart';
import 'proto/douyin.pb.dart';
import 'package:simple_live_core/simple_live_core.dart';

class DouyinDanmakuArgs {
  final String webRid;
  final String roomId;
  final String userId;
  final String cookie;

  DouyinDanmakuArgs({
    required this.webRid,
    required this.roomId,
    required this.userId,
    required this.cookie,
  });

  @override
  String toString() {
    return json.encode({
      'webRid': webRid,
      'roomId': roomId,
      'userId': userId,
      'cookie': cookie,
    });
  }
}

class DouyinDanmaku implements LiveDanmaku {
  @override
  int heartbeatTime = 10 * 1000;

  @override
  Function(LiveMessage msg)? onMessage;
  @override
  Function(String msg)? onClose;
  @override
  Function()? onReady;

  String serverUrl =
      'wss://webcast3-ws-web-lq.douyin.com/webcast/im/push/v2/';
  late DouyinDanmakuArgs danmakuArgs;
  WebSocketUtil? webScoketUtils;

  @override
  Future start(dynamic args) async {
    danmakuArgs = args as DouyinDanmakuArgs;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final uri = Uri.parse(serverUrl).replace(
      scheme: 'wss',
      queryParameters: {
        'app_name': 'douyin_web',
        'version_code': '180800',
        'webcast_sdk_version': '1.3.0',
        'update_version_code': '1.3.0',
        'compress': 'gzip',
        'cursor': 'h-1_t-${ts}_r-1_d-1_u-1',
        'host': 'https://live.douyin.com',
        'aid': '6383',
        'live_id': '1',
        'did_rule': '3',
        'debug': 'false',
        'maxCacheMessageNumber': '20',
        'endpoint': 'live_pc',
        'support_wrds': '1',
        'im_path': '/webcast/im/fetch/',
        'user_unique_id': danmakuArgs.userId,
        'device_platform': 'web',
        'cookie_enabled': 'true',
        'screen_width': '1920',
        'screen_height': '1080',
        'browser_language': 'zh-CN',
        'browser_platform': 'Win32',
        'browser_name': 'Mozilla',
        'browser_version': DouyinSite.kDefaultUserAgent.replaceAll(
          'Mozilla/',
          '',
        ),
        'browser_online': 'true',
        'tz_name': 'Asia/Shanghai',
        'identity': 'audience',
        'room_id': danmakuArgs.roomId,
        'heartbeatDuration': '0',
      },
    );

    final sign =
        DouyinSign.getSignature(danmakuArgs.roomId, danmakuArgs.userId);
    final url = '$uri&signature=$sign';
    final backupUrl =
        url.replaceAll('webcast3-ws-web-lq', 'webcast5-ws-web-lf');

    webScoketUtils = WebSocketUtil(
      url: url,
      backupUrl: backupUrl,
      headers: {
        'User-Agent': DouyinSite.kDefaultUserAgent,
        'Cookie': danmakuArgs.cookie,
        'Origin': 'https://live.douyin.com',
      },
      heartBeatTime: heartbeatTime,
      onMessage: (e) {
        decodeMessage(e);
      },
      onReady: () {
        onReady?.call();
        joinRoom();
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

  void joinRoom() {
    final obj = PushFrame();
    obj.payloadType = 'hb';
    webScoketUtils?.sendMessage(obj.writeToBuffer());
  }

  @override
  void heartbeat() {
    final obj = PushFrame();
    obj.payloadType = 'hb';
    webScoketUtils?.sendMessage(obj.writeToBuffer());
  }

  void decodeMessage(List<int> args) {
    try {
      final wssPackage = PushFrame.fromBuffer(args);
      final logId = wssPackage.logId;
      final decompressed = gzip.decode(wssPackage.payload);
      final payloadPackage = Response.fromBuffer(decompressed);

      if (payloadPackage.needAck) {
        sendAck(logId, payloadPackage.internalExt);
      }

      for (final msg in payloadPackage.messagesList) {
        if (msg.method == 'WebcastChatMessage') {
          unPackWebcastChatMessage(msg.payload);
        } else if (msg.method == 'WebcastRoomUserSeqMessage') {
          unPackWebcastRoomUserSeqMessage(msg.payload);
        }
      }
    } catch (e) {
      CoreLog.error(e);
    }
  }

  void unPackWebcastChatMessage(List<int> payload) {
    final chatMessage = ChatMessage.fromBuffer(payload);
    onMessage?.call(LiveMessage(
      type: LiveMessageType.chat,
      color: LiveMessageColor.white,
      message: chatMessage.content,
      userName: chatMessage.user.nickName,
    ));
  }

  void unPackWebcastRoomUserSeqMessage(List<int> payload) {
    final roomUserSeqMessage = RoomUserSeqMessage.fromBuffer(payload);
    onMessage?.call(LiveMessage(
      type: LiveMessageType.online,
      data: roomUserSeqMessage.totalUser.toInt(),
      color: LiveMessageColor.white,
      message: '',
      userName: '',
    ));
  }

  void sendAck(Int64 logId, String internalExt) {
    final obj = PushFrame();
    obj.payloadType = 'ack';
    obj.logId = logId;
    obj.payloadType = internalExt;
    webScoketUtils?.sendMessage(obj.writeToBuffer());
  }

  @override
  Future stop() async {
    onMessage = null;
    onClose = null;
    webScoketUtils?.close();
  }
}
