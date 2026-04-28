import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:brotli/brotli.dart';

import '../common/binary_writer.dart';
import '../common/convert_helper.dart';
import '../common/core_log.dart';
import '../common/web_socket_util.dart';
import '../interface/live_danmaku.dart';
import '../model/live_message.dart';

class BiliBiliDanmakuArgs {
  final int roomId;
  final String token;
  final String buvid;
  final String serverHost;
  final int uid;
  final String cookie;

  BiliBiliDanmakuArgs({
    required this.roomId,
    required this.token,
    required this.serverHost,
    required this.buvid,
    required this.uid,
    required this.cookie,
  });

  @override
  String toString() => json.encode({
        "roomId": roomId,
        "token": token,
        "serverHost": serverHost,
        "buvid": buvid,
        "uid": uid,
        "cookie": cookie,
      });
}

class BiliBiliDanmaku implements LiveDanmaku {
  @override
  int heartbeatTime = 60 * 1000;

  @override
  Function(LiveMessage msg)? onMessage;
  @override
  Function(String msg)? onClose;
  @override
  Function()? onReady;

  WebSocketUtil? ws;
  late BiliBiliDanmakuArgs danmakuArgs;

  @override
  Future start(dynamic args) async {
    danmakuArgs = args as BiliBiliDanmakuArgs;
    ws = WebSocketUtil(
      url: "wss://${args.serverHost}/sub",
      heartBeatTime: heartbeatTime,
      headers: args.cookie.isEmpty ? null : {"cookie": args.cookie},
      onMessage: (e) => decodeMessage(e),
      onReady: () {
        onReady?.call();
        joinRoom(danmakuArgs);
      },
      onHeartBeat: () => heartbeat(),
      onReconnect: () => onClose?.call("与服务器断开连接，正在尝试重连"),
      onClose: (e) => onClose?.call("服务器连接失败$e"),
    );
    ws?.connect();
  }

  void joinRoom(BiliBiliDanmakuArgs args) {
    var joinData = encodeData(
      json.encode({
        "uid": args.uid,
        "roomid": args.roomId,
        "protover": 3,
        "buvid": args.buvid,
        "platform": "web",
        "type": 2,
        "key": args.token,
      }),
      7,
    );
    ws?.sendMessage(joinData);
  }

  @override
  void heartbeat() {
    ws?.sendMessage(encodeData("", 2));
  }

  @override
  Future stop() async {
    onMessage = null;
    onClose = null;
    ws?.close();
  }

  List<int> encodeData(String msg, int action) {
    var data = utf8.encode(msg);
    var length = data.length + 16;
    var writer = BinaryWriter([]);
    writer.writeInt(length, 4); // 数据包长度
    writer.writeInt(16, 2); // 头部长度
    writer.writeInt(0, 2); // 协议版本: 0=JSON
    writer.writeInt(action, 4); // 操作类型
    writer.writeInt(1, 4); // 固定1
    writer.writeBytes(data);
    return writer.buffer;
  }

  void decodeMessage(List<int> data) {
    try {
      int protocolVersion = _readInt(data, 6, 2);
      int operation = _readInt(data, 8, 4);
      var body = data.skip(16).toList();

      if (operation == 3) {
        // 心跳回应：房间人气值
        var online = _readInt(body, 0, 4);
        onMessage?.call(LiveMessage(
          type: LiveMessageType.online,
          data: online,
          color: LiveMessageColor.white,
          message: "",
          userName: "",
        ));
      } else if (operation == 5) {
        // 通知消息
        if (protocolVersion == 2) {
          body = zlib.decode(body);
        } else if (protocolVersion == 3) {
          body = brotli.decode(body);
        }
        var text = utf8.decode(body, allowMalformed: true);
        var group =
            text.split(RegExp(r"[\x00-\x1f]+", unicode: true, multiLine: true));
        for (var item
            in group.where((x) => x.length > 2 && x.startsWith('{'))) {
          parseMessage(item);
        }
      }
    } catch (e) {
      CoreLog.error(e);
    }
  }

  void parseMessage(String jsonMessage) {
    try {
      var obj = json.decode(jsonMessage);
      var cmd = obj["cmd"].toString();
      if (cmd.contains("DANMU_MSG")) {
        if (obj["info"] != null && obj["info"].length != 0) {
          var message = obj["info"][1].toString();
          var color = asT<int?>(obj["info"][0][3]) ?? 0;
          if (obj["info"][2] != null && obj["info"][2].length != 0) {
            var username = obj["info"][2][1].toString();
            onMessage?.call(LiveMessage(
              type: LiveMessageType.chat,
              userName: username,
              message: message,
              color: color == 0
                  ? LiveMessageColor.white
                  : LiveMessageColor.numberToColor(color),
            ));
          }
        }
      } else if (cmd == "SUPER_CHAT_MESSAGE") {
        if (obj["data"] == null) return;
        LiveSuperChatMessage sc = LiveSuperChatMessage(
          backgroundBottomColor:
              obj["data"]["background_bottom_color"].toString(),
          backgroundColor: obj["data"]["background_color"].toString(),
          endTime:
              DateTime.fromMillisecondsSinceEpoch(obj["data"]["end_time"] * 1000),
          face: "${obj["data"]["user_info"]["face"]}@200w.jpg",
          message: obj["data"]["message"].toString(),
          price: obj["data"]["price"],
          startTime: DateTime.fromMillisecondsSinceEpoch(
              obj["data"]["start_time"] * 1000),
          userName: obj["data"]["user_info"]["uname"].toString(),
        );
        onMessage?.call(LiveMessage(
          type: LiveMessageType.superChat,
          userName: "SUPER_CHAT_MESSAGE",
          message: "SUPER_CHAT_MESSAGE",
          color: LiveMessageColor.white,
          data: sc,
        ));
      }
    } catch (e) {
      CoreLog.error(e);
    }
  }

  int _readInt(List<int> buffer, int start, int len) {
    var bytes =
        Uint8List.fromList(buffer.getRange(start, start + len).toList());
    var byteBuffer = bytes.buffer;
    var data = ByteData.view(byteBuffer);
    if (len == 1) return data.getUint8(0);
    if (len == 2) return data.getInt16(0, Endian.big);
    if (len == 4) return data.getInt32(0, Endian.big);
    if (len == 8) return data.getInt64(0, Endian.big);
    return 0;
  }
}
