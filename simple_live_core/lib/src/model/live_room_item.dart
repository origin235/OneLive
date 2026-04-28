import 'dart:convert';

class LiveRoomItem {
  final String roomId;
  final String title;
  final String cover;
  final String userName;
  final int online;

  LiveRoomItem({
    required this.roomId,
    required this.title,
    required this.cover,
    required this.userName,
    this.online = 0,
  });

  @override
  String toString() {
    return json.encode({
      "roomId": roomId,
      "title": title,
      "cover": cover,
      "userName": userName,
      "online": online,
    });
  }
}
