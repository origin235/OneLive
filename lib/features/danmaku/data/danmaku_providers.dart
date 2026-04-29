import 'package:simple_live_core/simple_live_core.dart';

/// 弹幕客户端工厂 —— 根据平台创建对应的 LiveDanmaku 实例（不启动）
class DanmakuFactory {
  static LiveDanmaku? create(String platformId) {
    switch (platformId) {
      case 'bilibili':
        return BiliBiliDanmaku();
      default:
        return null;
    }
  }
}
