import 'package:flutter/material.dart';
import 'package:simple_live_core/simple_live_core.dart';

class _DanmakuItem {
  final String text;
  final Color color;
  double x;
  final double width;
  final int track;

  _DanmakuItem({
    required this.text,
    required this.color,
    required this.x,
    required this.width,
    required this.track,
  });
}

/// 弹幕覆盖层 — CustomPainter 自研弹幕渲染
class DanmakuOverlay extends StatefulWidget {
  final LiveDanmaku? danmaku;
  final dynamic danmakuData;
  final bool enabled;
  final double opacity;
  final double fontSize;
  final double speed;
  final double area;

  const DanmakuOverlay({
    super.key,
    this.danmaku,
    this.danmakuData,
    this.enabled = true,
    this.opacity = 1.0,
    this.fontSize = 18.0,
    this.speed = 150.0,
    this.area = 0.8,
  });

  @override
  State<DanmakuOverlay> createState() => _DanmakuOverlayState();
}

class _DanmakuOverlayState extends State<DanmakuOverlay>
    with TickerProviderStateMixin {
  final List<_DanmakuItem> _items = [];
  AnimationController? _controller;
  DateTime _lastTick = DateTime.now();
  double _screenWidth = 0;
  int _trackCount = 6;
  static const double _baseTrackHeight = 36;
  bool _danmakuStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick)
      ..repeat();
    _maybeStartDanmaku();
  }

  @override
  void didUpdateWidget(covariant DanmakuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.danmaku != oldWidget.danmaku ||
        widget.danmakuData != oldWidget.danmakuData) {
      _maybeStartDanmaku();
    }
  }

  void _maybeStartDanmaku() {
    final d = widget.danmaku;
    final data = widget.danmakuData;
    if (d == null || data == null || _danmakuStarted) return;
    _danmakuStarted = true;

    d.onMessage = (msg) {
      if (!widget.enabled || msg.type != LiveMessageType.chat) return;
      _addMessage(msg.message, msg.userName, msg.color);
    };
    d.start(data);
  }

  void _addMessage(String message, String userName, LiveMessageColor color) {
    final text = userName.isNotEmpty ? '$userName: $message' : message;
    final textStyle = TextStyle(
      color: Color.fromARGB(
        (255 * widget.opacity).toInt().clamp(0, 255),
        color.r,
        color.g,
        color.b,
      ),
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w600,
      shadows: const [
        Shadow(color: Colors.black, blurRadius: 2),
      ],
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _screenWidth * 2);

    final width = textPainter.width;
    final track = _pickTrack();

    setState(() {
      _items.add(_DanmakuItem(
        text: text,
        color: Color.fromARGB(
          (255 * widget.opacity).toInt().clamp(0, 255),
          color.r,
          color.g,
          color.b,
        ),
        x: _screenWidth,
        width: width,
        track: track,
      ));
    });
  }

  int _pickTrack() {
    final maxTrack = (_trackCount * widget.area).ceil().clamp(1, _trackCount);
    final trackOccupancy = List<double>.filled(_trackCount, 0);
    for (final item in _items) {
      final rightEdge = item.x + item.width;
      if (rightEdge > trackOccupancy[item.track]) {
        trackOccupancy[item.track] = rightEdge;
      }
    }
    int bestTrack = 0;
    double bestVal = double.infinity;
    for (int i = 0; i < maxTrack; i++) {
      if (trackOccupancy[i] < bestVal) {
        bestVal = trackOccupancy[i];
        bestTrack = i;
      }
    }
    return bestTrack;
  }

  void _onTick() {
    final now = DateTime.now();
    final deltaMs = now.difference(_lastTick).inMilliseconds;
    _lastTick = now;
    if (deltaMs <= 0) return;

    final deltaPx = widget.speed * deltaMs / 1000;
    final toRemove = <_DanmakuItem>[];

    for (final item in _items) {
      item.x -= deltaPx;
      if (item.x + item.width < -10) {
        toRemove.add(item);
      }
    }

    if (toRemove.isNotEmpty) {
      _items.removeWhere((e) => toRemove.contains(e));
    }

    if (toRemove.isNotEmpty || _items.isNotEmpty) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenWidth = constraints.maxWidth;
        _trackCount =
            (constraints.maxHeight / _baseTrackHeight).floor().clamp(1, 20);
        return IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _DanmakuPainter(
                items: _items,
                trackHeight: _baseTrackHeight,
                opacity: widget.opacity,
                fontSize: widget.fontSize,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DanmakuPainter extends CustomPainter {
  final List<_DanmakuItem> items;
  final double trackHeight;
  final double opacity;
  final double fontSize;

  _DanmakuPainter({
    required this.items,
    required this.trackHeight,
    required this.opacity,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      final y = item.track * trackHeight;
      final textStyle = TextStyle(
        color: item.color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        shadows: const [
          Shadow(color: Colors.black, blurRadius: 2),
        ],
      );
      final textPainter = TextPainter(
        text: TextSpan(text: item.text, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: size.width * 2);
      textPainter.paint(canvas, Offset(item.x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _DanmakuPainter oldDelegate) => true;
}
