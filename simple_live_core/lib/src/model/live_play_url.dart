import 'dart:convert';

class LivePlayUrl {
  final List<String> urls;
  final Map<String, String>? headers;

  LivePlayUrl({
    required this.urls,
    this.headers,
  });

  @override
  String toString() {
    return json.encode({
      "urls": urls,
      "headers": headers.toString(),
    });
  }
}
