import 'dart:convert';
import 'dart:math';

import 'package:html_unescape/html_unescape.dart';

import '../common/http_client.dart';
import '../danmaku/douyu_danmaku.dart';
import '../interface/live_danmaku.dart';
import '../interface/live_site.dart';
import '../model/live_anchor_item.dart';
import '../model/live_category.dart';
import '../model/live_category_result.dart';
import '../model/live_message.dart';
import '../model/live_play_quality.dart';
import '../model/live_play_url.dart';
import '../model/live_room_detail.dart';
import '../model/live_room_item.dart';
import '../model/live_search_result.dart';
import '../scripts/douyu_sign.dart';

class DouyuSite extends LiveSite {
  DouyuSite() {
    id = 'douyu';
    name = '斗鱼直播';
  }

  @override
  LiveDanmaku getDanmaku() => DouyuDanmaku();

  @override
  Future<List<LiveCategory>> getCategores() async {
    final result = await HttpClient.instance.getJson(
      'https://m.douyu.com/api/cate/list',
    );
    final List<LiveCategory> categories = [];
    final subCateList = result['data']['cate2Info'] as List;
    for (final item in result['data']['cate1Info']) {
      final cate1Id = item['cate1Id'];
      final cate1Name = item['cate1Name'];
      final List<LiveSubCategory> subCategories = [];
      subCateList.where((x) => x['cate1Id'] == cate1Id).forEach((element) {
        subCategories.add(LiveSubCategory(
          pic: element['icon'],
          id: element['cate2Id'].toString(),
          parentId: cate1Id.toString(),
          name: element['cate2Name'].toString(),
        ));
      });
      categories.add(LiveCategory(
        id: cate1Id.toString(),
        name: cate1Name.toString(),
        children: subCategories,
      ));
    }
    categories.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
    return categories;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveSubCategory category,
      {int page = 1}) async {
    final result = await HttpClient.instance.getJson(
      'https://www.douyu.com/gapi/rkc/directory/mixList/2_${category.id}/$page',
    );
    final items = <LiveRoomItem>[];
    for (final item in result['data']['rl']) {
      if (item['type'] != 1) continue;
      items.add(LiveRoomItem(
        cover: item['rs16'].toString(),
        online: item['ol'],
        roomId: item['rid'].toString(),
        title: item['rn'].toString(),
        userName: item['nn'].toString(),
      ));
    }
    final hasMore = page < result['data']['pgcnt'];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) async {
    final result = await HttpClient.instance.getJson(
      'https://www.douyu.com/japi/weblist/apinc/allpage/6/$page',
    );
    final items = <LiveRoomItem>[];
    for (final item in result['data']['rl']) {
      if (item['type'] != 1) continue;
      items.add(LiveRoomItem(
        cover: item['rs16'].toString(),
        online: item['ol'],
        roomId: item['rid'].toString(),
        title: item['rn'].toString(),
        userName: item['nn'].toString(),
      ));
    }
    final hasMore = page < result['data']['pgcnt'];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
    final roomInfo = await _getRoomInfo(roomId);
    final h5RoomInfo = await HttpClient.instance.getJson(
      'https://www.douyu.com/swf_api/h5room/$roomId',
      header: {
        'referer': 'https://www.douyu.com/$roomId',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43',
      },
    );
    final showTime = h5RoomInfo['data']?['show_time']?.toString();

    final jsEncResult = await HttpClient.instance.getText(
      'https://www.douyu.com/swf_api/homeH5Enc?rids=$roomId',
      header: {
        'referer': 'https://www.douyu.com/$roomId',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43',
      },
    );
    final crptext =
        json.decode(jsEncResult)['data']['room$roomId'].toString();

    return LiveRoomDetail(
      cover: roomInfo['room_pic'].toString(),
      online:
          int.tryParse(roomInfo['room_biz_all']['hot'].toString()) ?? 0,
      roomId: roomInfo['room_id'].toString(),
      title: roomInfo['room_name'].toString(),
      userName: roomInfo['owner_name'].toString(),
      userAvatar: roomInfo['owner_avatar'].toString(),
      introduction: roomInfo['show_details'].toString(),
      notice: '',
      status: roomInfo['show_status'] == 1 && roomInfo['videoLoop'] != 1,
      danmakuData: roomInfo['room_id'].toString(),
      data: DouyuSign.getSign(crptext, roomInfo['room_id'].toString()),
      url: 'https://www.douyu.com/$roomId',
      isRecord: roomInfo['videoLoop'] == 1,
      showTime: showTime,
    );
  }

  Future<Map> _getRoomInfo(String roomId) async {
    final result = await HttpClient.instance.getJson(
      'https://www.douyu.com/betard/$roomId',
      header: {
        'referer': 'https://www.douyu.com/$roomId',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43',
      },
    );
    Map roomInfo;
    if (result is String) {
      roomInfo = json.decode(result)['room'];
    } else {
      roomInfo = result['room'];
    }
    return roomInfo;
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites(
      {required LiveRoomDetail detail}) async {
    var data = detail.data.toString();
    data += '&cdn=&rate=-1&ver=Douyu_223061205&iar=1&ive=1&hevc=0&fa=0';
    final result = await HttpClient.instance.postJson(
      'https://www.douyu.com/lapi/live/getH5Play/${detail.roomId}',
      data: data,
      formUrlEncoded: true,
    );

    final cdns = <String>[];
    for (final item in result['data']['cdnsWithName']) {
      cdns.add(item['cdn'].toString());
    }
    cdns.sort((a, b) {
      if (a.startsWith('scdn') && !b.startsWith('scdn')) return 1;
      if (!a.startsWith('scdn') && b.startsWith('scdn')) return -1;
      return 0;
    });

    final List<LivePlayQuality> qualities = [];
    for (final item in result['data']['multirates']) {
      qualities.add(LivePlayQuality(
        quality: item['name'].toString(),
        data: DouyuPlayData(item['rate'], cdns),
      ));
    }
    return qualities;
  }

  @override
  Future<LivePlayUrl> getPlayUrls(
      {required LiveRoomDetail detail,
      required LivePlayQuality quality}) async {
    final args = detail.data.toString();
    final data = quality.data as DouyuPlayData;
    final List<String> urls = [];
    for (final cdn in data.cdns) {
      final url = await _getPlayUrl(detail.roomId, args, data.rate, cdn);
      if (url.isNotEmpty) urls.add(url);
    }
    return LivePlayUrl(urls: urls);
  }

  Future<String> _getPlayUrl(
      String roomId, String args, int rate, String cdn) async {
    final fullArgs = '$args&cdn=$cdn&rate=$rate';
    final result = await HttpClient.instance.postJson(
      'https://www.douyu.com/lapi/live/getH5Play/$roomId',
      data: fullArgs,
      header: {
        'referer': 'https://www.douyu.com/$roomId',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.43',
      },
      formUrlEncoded: true,
    );
    return '${result['data']['rtmp_url']}/${HtmlUnescape().convert(result['data']['rtmp_live'].toString())}';
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword,
      {int page = 1}) async {
    final did = _generateRandomString(32);
    final result = await HttpClient.instance.getJson(
      'https://www.douyu.com/japi/search/api/searchShow',
      queryParameters: {'kw': keyword, 'page': page, 'pageSize': 20},
      header: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.51',
        'referer': 'https://www.douyu.com/search/',
        'Cookie': 'dy_did=$did;acf_did=$did',
      },
    );
    if (result['error'] != 0) throw Exception(result['msg']);
    final items = <LiveRoomItem>[];
    for (final item in result['data']['relateShow']) {
      items.add(LiveRoomItem(
        roomId: item['rid'].toString(),
        title: item['roomName'].toString(),
        cover: item['roomSrc'].toString(),
        userName: item['nickName'].toString(),
        online: _parseHotNum(item['hot'].toString()),
      ));
    }
    final hasMore = result['data']['relateShow'].isNotEmpty;
    return LiveSearchRoomResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword,
      {int page = 1}) async {
    final did = _generateRandomString(32);
    final result = await HttpClient.instance.getJson(
      'https://www.douyu.com/japi/search/api/searchUser',
      queryParameters: {
        'kw': keyword,
        'page': page,
        'pageSize': 20,
        'filterType': 1,
      },
      header: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1823.51',
        'referer': 'https://www.douyu.com/search/',
        'Cookie': 'dy_did=$did;acf_did=$did',
      },
    );
    final items = <LiveAnchorItem>[];
    for (final item in result['data']['relateUser']) {
      final liveStatus =
          (int.tryParse(item['anchorInfo']['isLive'].toString()) ?? 0) == 1;
      final roomType =
          int.tryParse(item['anchorInfo']['roomType'].toString()) ?? 0;
      items.add(LiveAnchorItem(
        roomId: item['anchorInfo']['rid'].toString(),
        avatar: item['anchorInfo']['avatar'].toString(),
        userName: item['anchorInfo']['nickName'].toString(),
        liveStatus: liveStatus && roomType == 0,
      ));
    }
    final hasMore = result['data']['relateUser'].isNotEmpty;
    return LiveSearchAnchorResult(hasMore: hasMore, items: items);
  }

  @override
  Future<bool> getLiveStatus({required String roomId}) async {
    final roomInfo = await _getRoomInfo(roomId);
    return roomInfo['show_status'] == 1 && roomInfo['videoLoop'] != 1;
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage(
      {required String roomId}) {
    return Future.value([]);
  }

  int _parseHotNum(String hn) {
    try {
      var num = double.parse(hn.replaceAll('万', ''));
      if (hn.contains('万')) num *= 10000;
      return num.round();
    } catch (_) {
      return -999;
    }
  }

  String _generateRandomString(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(16));
    final buffer = StringBuffer();
    for (final item in values) {
      buffer.write(item.toRadixString(16));
    }
    return buffer.toString();
  }
}

class DouyuPlayData {
  final int rate;
  final List<String> cdns;
  DouyuPlayData(this.rate, this.cdns);
}
