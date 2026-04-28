import 'dart:async';

import '../model/live_message.dart';

class LiveDanmaku {
  Function(LiveMessage msg)? onMessage;
  Function(String msg)? onClose;
  Function()? onReady;

  /// 心跳间隔 (ms)
  int heartbeatTime = 0;

  /// 发送心跳
  void heartbeat() {}

  /// 开始接收弹幕
  Future start(dynamic args) {
    return Future.value();
  }

  /// 停止接收弹幕
  Future stop() {
    return Future.value();
  }
}
