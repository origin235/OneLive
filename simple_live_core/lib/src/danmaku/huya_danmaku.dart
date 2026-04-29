import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../common/web_socket_util.dart';
import '../interface/live_danmaku.dart';
import '../model/live_message.dart';
import '../model/tars/huya_danmaku.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:tars_dart/tars/codec/tars_input_stream.dart';
import 'package:tars_dart/tars/codec/tars_output_stream.dart';

class HuyaDanmakuArgs {
  final int ayyuid;
  final int topSid;
  final int subSid;

  HuyaDanmakuArgs({
    required this.ayyuid,
    required this.topSid,
    required this.subSid,
  });

  @override
  String toString() {
    return json.encode({
      'ayyuid': ayyuid,
      'topSid': topSid,
      'subSid': subSid,
    });
  }
}

class HuyaDanmaku implements LiveDanmaku {
  @override
  int heartbeatTime = 60 * 1000;

  @override
  Function(LiveMessage msg)? onMessage;
  @override
  Function(String msg)? onClose;
  @override
  Function()? onReady;

  String serverUrl = 'wss://cdnws.api.huya.com';
  WebSocketUtil? webScoketUtils;

  final heartbeatData = base64.decode('ABQdAAwsNgBM');

  late HuyaDanmakuArgs danmakuArgs;

  @override
  Future start(dynamic args) async {
    danmakuArgs = args as HuyaDanmakuArgs;
    webScoketUtils = WebSocketUtil(
      url: serverUrl,
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
    final joinData =
        getJoinData(danmakuArgs.ayyuid, danmakuArgs.topSid, danmakuArgs.topSid);
    webScoketUtils?.sendMessage(joinData);
  }

  List<int> getJoinData(int ayyuid, int tid, int sid) {
    try {
      final oos = TarsOutputStream();
      oos.write(ayyuid, 0);
      oos.write(true, 1);
      oos.write('', 2);
      oos.write('', 3);
      oos.write(tid, 4);
      oos.write(sid, 5);
      oos.write(0, 6);
      oos.write(0, 7);

      final wscmd = TarsOutputStream();
      wscmd.write(1, 0);
      wscmd.write(oos.toUint8List(), 1);
      return wscmd.toUint8List();
    } catch (e) {
      CoreLog.error(e);
      return [];
    }
  }

  @override
  void heartbeat() {
    webScoketUtils?.sendMessage(heartbeatData);
  }

  @override
  Future stop() async {
    onMessage = null;
    onClose = null;
    webScoketUtils?.close();
  }

  void decodeMessage(List<int> data) {
    try {
      var stream = TarsInputStream(Uint8List.fromList(data));
      final type = stream.read(0, 0, false);
      if (type == 7) {
        stream = TarsInputStream(stream.readBytes(1, false));
        final wSPushMessage = HYPushMessage();
        wSPushMessage.readFrom(stream);
        if (wSPushMessage.uri == 1400) {
          final messageNotice = HYMessage();
          messageNotice.readFrom(
              TarsInputStream(Uint8List.fromList(wSPushMessage.msg)));
          final uname = messageNotice.userInfo.nickName;
          final content = messageNotice.content;
          final color = messageNotice.bulletFormat.fontColor;

          onMessage?.call(LiveMessage(
            type: LiveMessageType.chat,
            color: color <= 0
                ? LiveMessageColor.white
                : LiveMessageColor.numberToColor(color),
            message: content,
            userName: uname,
          ));
        } else if (wSPushMessage.uri == 8006) {
          var s = TarsInputStream(Uint8List.fromList(wSPushMessage.msg));
          final online = s.read(0, 0, false) as int;
          onMessage?.call(LiveMessage(
            type: LiveMessageType.online,
            data: online,
            color: LiveMessageColor.white,
            message: '',
            userName: '',
          ));
        }
      }
    } catch (e) {
      CoreLog.error(e);
    }
  }
}
