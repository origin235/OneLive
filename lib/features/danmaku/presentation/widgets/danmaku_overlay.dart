import 'package:flutter/material.dart';

/// 弹幕覆盖层 —— 阶段 4 实现 CustomPainter 弹幕渲染
class DanmakuOverlay extends StatelessWidget {
  const DanmakuOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: SizedBox.expand(),
    );
  }
}
