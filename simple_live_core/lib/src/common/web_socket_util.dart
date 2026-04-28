import 'dart:async';

import 'package:web_socket_channel/io.dart';

enum SocketStatus {
  connected,
  failed,
  closed,
}

class WebSocketUtil {
  SocketStatus status = SocketStatus.closed;
  final String url;
  final String? backupUrl;
  final int heartBeatTime;
  final Function(dynamic)? onMessage;
  final Function(String msg)? onClose;
  final Function()? onReconnect;
  final Function()? onReady;
  final Function()? onHeartBeat;
  Map<String, dynamic>? headers;

  WebSocketUtil({
    required this.url,
    required this.heartBeatTime,
    this.onMessage,
    this.onClose,
    this.onReconnect,
    this.onReady,
    this.onHeartBeat,
    this.headers,
    this.backupUrl,
  });

  IOWebSocketChannel? webSocket;
  Timer? heartBeatTimer;
  int reconnectTime = 0;
  Timer? reconnectTimer;
  int maxReconnectTime = 5;
  StreamSubscription<dynamic>? streamSubscription;

  void connect({bool retry = false}) async {
    close();
    try {
      var wsurl = url;
      if (backupUrl != null && backupUrl!.isNotEmpty && retry) {
        wsurl = backupUrl!;
      }
      webSocket = IOWebSocketChannel.connect(
        wsurl,
        connectTimeout: Duration(seconds: 10),
        headers: headers,
      );
      await webSocket?.ready;
      ready();
    } catch (e) {
      if (!retry) {
        connect(retry: true);
        return;
      }
      onError(e, e);
    }
  }

  void ready() {
    status = SocketStatus.connected;
    streamSubscription = webSocket?.stream.listen(
      (data) => receiveMessage(data),
      onError: (e, s) => onError(e, s),
      onDone: onDone,
    );
    onReady?.call();
    initHeartBeat();
  }

  void initHeartBeat() {
    heartBeatTimer = Timer.periodic(
      Duration(milliseconds: heartBeatTime),
      (timer) {
        onHeartBeat?.call();
      },
    );
  }

  void receiveMessage(dynamic data) {
    reconnectTime = 0;
    onMessage?.call(data);
  }

  void onError(e, s) {
    status = SocketStatus.failed;
    onClose?.call(e.toString());
  }

  void onDone() {
    if (status == SocketStatus.closed) return;
    onReconnect?.call();
    reconnect();
  }

  void sendMessage(dynamic message) {
    if (status == SocketStatus.connected) {
      webSocket?.sink.add(message);
    }
  }

  void close() {
    status = SocketStatus.closed;
    streamSubscription?.cancel();
    reconnectTimer?.cancel();
    reconnectTimer = null;
    webSocket?.sink.close();
    heartBeatTimer?.cancel();
    heartBeatTimer = null;
  }

  void reconnect() {
    status = SocketStatus.closed;
    if (reconnectTime < maxReconnectTime) {
      reconnectTime++;
      reconnectTimer ??= Timer.periodic(Duration(seconds: 5), (timer) {
        connect();
      });
    } else {
      onClose?.call("重连超过最大次数，与服务器断开连接");
      reconnectTimer?.cancel();
      reconnectTimer = null;
      close();
      return;
    }
  }
}
