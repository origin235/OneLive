import 'dart:convert';

class LivePlayQuality {
  final String quality;
  final dynamic data;
  final int sort;

  LivePlayQuality({
    required this.quality,
    required this.data,
    this.sort = 0,
  });

  @override
  String toString() {
    return json.encode({
      "quality": quality,
      "data": data.toString(),
    });
  }
}
