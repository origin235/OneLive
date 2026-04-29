import 'dart:convert';
import 'dart:math';

import '../common/convert_helper.dart';
import '../common/core_log.dart';
import '../common/http_client.dart';
import '../danmaku/douyin_danmaku.dart';
import '../interface/live_danmaku.dart';
import '../interface/live_site.dart';
import '../model/live_category.dart';
import '../model/live_category_result.dart';
import '../model/live_message.dart';
import '../model/live_play_quality.dart';
import '../model/live_play_url.dart';
import '../model/live_room_detail.dart';
import '../model/live_room_item.dart';
import '../model/live_search_result.dart';
import '../scripts/douyin_sign.dart';

class DouyinSite extends LiveSite {
  static const String kDefaultUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.97 Safari/537.36 Core/1.116.567.400 QQBrowser/19.7.6764.400';
  static const String kDefaultReferer = 'https://live.douyin.com';
  static const String kDefaultAuthority = 'live.douyin.com';
  static const String kDefaultCookie =
      'ttwid=1%7CB1qls3GdnZhUov9o2NxOMxxYS2ff6OSvEWbv0ytbES4%7C1680522049%7C280d802d6d478e3e78d0c807f7c487e7ffec0ae4e5fdd6a0fe74c3c6af149511';

  String cookie = '';

  DouyinSite() {
    id = 'douyin';
    name = '抖音直播';
  }

  Map<String, dynamic> get headers => {
        'Authority': kDefaultAuthority,
        'Referer': kDefaultReferer,
        'User-Agent': kDefaultUserAgent,
      };

  Future<Map<String, dynamic>> getRequestHeaders() async {
    if (cookie.isNotEmpty) {
      headers['cookie'] = cookie;
      return headers;
    }
    headers['cookie'] = kDefaultCookie;
    return headers;
  }

  @override
  LiveDanmaku getDanmaku() => DouyinDanmaku();

  @override
  Future<List<LiveCategory>> getCategores() async {
    final List<LiveCategory> categories = [];
    final result = await HttpClient.instance.getText(
      'https://live.douyin.com/',
      header: await getRequestHeaders(),
    );
    var renderData =
        RegExp(r'\{\\"pathname\\":\\"\/\\",\\"categoryData.*?\]\\n')
                .firstMatch(result)
                ?.group(0) ??
            '';
    final renderDataJson = json.decode(renderData
        .trim()
        .replaceAll('\\"', '"')
        .replaceAll(r'\\', r'\')
        .replaceAll(']\\n', ''));

    for (final item in renderDataJson['categoryData']) {
      final List<LiveSubCategory> subs = [];
      final id = '${item['partition']['id_str']},${item['partition']['type']}';
      for (final subItem in item['sub_partition']) {
        subs.add(LiveSubCategory(
          id:
              '${subItem['partition']['id_str']},${subItem['partition']['type']}',
          name: asT<String?>(subItem['partition']['title']) ?? '',
          parentId: id,
          pic: '',
        ));
      }
      final category = LiveCategory(
        children: subs,
        id: id,
        name: asT<String?>(item['partition']['title']) ?? '',
      );
      subs.insert(
        0,
        LiveSubCategory(
          id: category.id,
          name: category.name,
          parentId: category.id,
          pic: '',
        ),
      );
      categories.add(category);
    }
    return categories;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveSubCategory category,
      {int page = 1}) async {
    final ids = category.id.split(',');
    final partitionId = ids[0];
    final partitionType = ids[1];

    const serverUrl =
        'https://live.douyin.com/webcast/web/partition/detail/room/v2/';
    final uri = Uri.parse(serverUrl).replace(queryParameters: {
      'aid': '6383',
      'app_name': 'douyin_web',
      'live_id': '1',
      'device_platform': 'web',
      'language': 'zh-CN',
      'enter_from': 'link_share',
      'cookie_enabled': 'true',
      'screen_width': '1980',
      'screen_height': '1080',
      'browser_language': 'zh-CN',
      'browser_platform': 'Win32',
      'browser_name': 'Edge',
      'browser_version': '125.0.0.0',
      'browser_online': 'true',
      'count': '15',
      'offset': ((page - 1) * 15).toString(),
      'partition': partitionId,
      'partition_type': partitionType,
      'req_from': '2',
    });
    final requestUrl = DouyinSign.getAbogusUrl(uri.toString(), kDefaultUserAgent);

    final result = await HttpClient.instance.getJson(
      requestUrl,
      header: await getRequestHeaders(),
    );

    final hasMore = (result['data']['data'] as List).length >= 15;
    final items = <LiveRoomItem>[];
    for (final item in result['data']['data']) {
      items.add(LiveRoomItem(
        roomId: item['web_rid'],
        title: item['room']['title'].toString(),
        cover: item['room']['cover']['url_list'][0].toString(),
        userName: item['room']['owner']['nickname'].toString(),
        online: int.tryParse(
              item['room']['room_view_stats']['display_value'].toString(),
            ) ??
            0,
      ));
    }
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) async {
    const serverUrl =
        'https://live.douyin.com/webcast/web/partition/detail/room/v2/';
    final uri = Uri.parse(serverUrl).replace(queryParameters: {
      'aid': '6383',
      'app_name': 'douyin_web',
      'live_id': '1',
      'device_platform': 'web',
      'language': 'zh-CN',
      'enter_from': 'link_share',
      'cookie_enabled': 'true',
      'screen_width': '1980',
      'screen_height': '1080',
      'browser_language': 'zh-CN',
      'browser_platform': 'Win32',
      'browser_name': 'Edge',
      'browser_version': '125.0.0.0',
      'browser_online': 'true',
      'count': '15',
      'offset': ((page - 1) * 15).toString(),
      'partition': '720',
      'partition_type': '1',
      'req_from': '2',
    });
    final requestUrl = DouyinSign.getAbogusUrl(uri.toString(), kDefaultUserAgent);

    final result = await HttpClient.instance.getJson(
      requestUrl,
      header: await getRequestHeaders(),
    );

    final hasMore = (result['data']['data'] as List).length >= 15;
    final items = <LiveRoomItem>[];
    for (final item in result['data']['data']) {
      items.add(LiveRoomItem(
        roomId: item['web_rid'],
        title: item['room']['title'].toString(),
        cover: item['room']['cover']['url_list'][0].toString(),
        userName: item['room']['owner']['nickname'].toString(),
        online: int.tryParse(
              item['room']['room_view_stats']['display_value'].toString(),
            ) ??
            0,
      ));
    }
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
    if (roomId.length <= 16) {
      return await _getRoomDetailByWebRid(roomId);
    }
    return await _getRoomDetailByRoomId(roomId);
  }

  Future<LiveRoomDetail> _getRoomDetailByRoomId(String roomId) async {
    final roomData = await _getRoomDataByRoomId(roomId);
    final webRid = roomData['data']['room']['owner']['web_rid'].toString();
    final userUniqueId = _generateRandomNumber(12).toString();
    final room = roomData['data']['room'];
    final owner = room['owner'];
    final status = asT<int?>(room['status']) ?? 0;

    if (status == 4) {
      return await _getRoomDetailByWebRid(webRid);
    }

    final roomStatus = status == 2;
    final headers = await getRequestHeaders();

    return LiveRoomDetail(
      roomId: webRid,
      title: room['title'].toString(),
      cover: roomStatus ? room['cover']['url_list'][0].toString() : '',
      userName: owner['nickname'].toString(),
      userAvatar: owner['avatar_thumb']['url_list'][0].toString(),
      online: roomStatus
          ? asT<int?>(room['room_view_stats']['display_value']) ?? 0
          : 0,
      status: roomStatus,
      url: 'https://live.douyin.com/$webRid',
      introduction: owner['signature'].toString(),
      notice: '',
      danmakuData: DouyinDanmakuArgs(
        webRid: webRid,
        roomId: roomId,
        userId: userUniqueId,
        cookie: headers['cookie'],
      ),
      data: room['stream_url'],
    );
  }

  Future<LiveRoomDetail> _getRoomDetailByWebRid(String webRid) async {
    try {
      return await _getRoomDetailByWebRidApi(webRid);
    } catch (e) {
      CoreLog.error(e);
    }
    return await _getRoomDetailByWebRidHtml(webRid);
  }

  Future<LiveRoomDetail> _getRoomDetailByWebRidApi(String webRid) async {
    final data = await _getRoomDataByApi(webRid);
    final roomData = data['data'][0];
    final userData = data['user'];
    final roomId = roomData['id_str'].toString();
    final userUniqueId = _generateRandomNumber(12).toString();
    final owner = roomData['owner'];
    final roomStatus = (asT<int?>(roomData['status']) ?? 0) == 2;
    final headers = await getRequestHeaders();

    return LiveRoomDetail(
      roomId: webRid,
      title: roomData['title'].toString(),
      cover: roomStatus ? roomData['cover']['url_list'][0].toString() : '',
      userName:
          roomStatus ? owner['nickname'].toString() : userData['nickname'].toString(),
      userAvatar: roomStatus
          ? owner['avatar_thumb']['url_list'][0].toString()
          : userData['avatar_thumb']['url_list'][0].toString(),
      online: roomStatus
          ? asT<int?>(roomData['room_view_stats']['display_value']) ?? 0
          : 0,
      status: roomStatus,
      url: 'https://live.douyin.com/$webRid',
      introduction: owner?['signature']?.toString() ?? '',
      notice: '',
      danmakuData: DouyinDanmakuArgs(
        webRid: webRid,
        roomId: roomId,
        userId: userUniqueId,
        cookie: headers['cookie'],
      ),
      data: roomStatus ? roomData['stream_url'] : {},
    );
  }

  Future<LiveRoomDetail> _getRoomDetailByWebRidHtml(String webRid) async {
    final roomData = await _getRoomDataByHtml(webRid);
    final roomId =
        roomData['roomStore']['roomInfo']['room']['id_str'].toString();
    final userUniqueId =
        roomData['userStore']['odin']['user_unique_id'].toString();
    final room = roomData['roomStore']['roomInfo']['room'];
    final owner = room['owner'];
    final anchor = roomData['roomStore']['roomInfo']['anchor'];
    final roomStatus = (asT<int?>(room['status']) ?? 0) == 2;
    final headers = await getRequestHeaders();

    return LiveRoomDetail(
      roomId: webRid,
      title: room['title'].toString(),
      cover: roomStatus ? room['cover']['url_list'][0].toString() : '',
      userName:
          roomStatus ? owner['nickname'].toString() : anchor['nickname'].toString(),
      userAvatar: roomStatus
          ? owner['avatar_thumb']['url_list'][0].toString()
          : anchor['avatar_thumb']['url_list'][0].toString(),
      online: roomStatus
          ? asT<int?>(room['room_view_stats']['display_value']) ?? 0
          : 0,
      status: roomStatus,
      url: 'https://live.douyin.com/$webRid',
      introduction: owner?['signature']?.toString() ?? '',
      notice: '',
      danmakuData: DouyinDanmakuArgs(
        webRid: webRid,
        roomId: roomId,
        userId: userUniqueId,
        cookie: headers['cookie'],
      ),
      data: roomStatus ? room['stream_url'] : {},
    );
  }

  Future<Map> _getRoomDataByHtml(String webRid) async {
    final dyCookie = await _getWebCookie(webRid);
    final result = await HttpClient.instance.getText(
      'https://live.douyin.com/$webRid',
      header: {
        'Authority': kDefaultAuthority,
        'Referer': kDefaultReferer,
        'Cookie': dyCookie,
        'User-Agent': kDefaultUserAgent,
      },
    );
    var renderData =
        RegExp(r'\{\\"state\\":\{\\"appStore.*?\]\\n')
                .firstMatch(result)
                ?.group(0) ??
            '';
    final str = renderData
        .trim()
        .replaceAll('\\"', '"')
        .replaceAll(r'\\', r'\')
        .replaceAll(']\\n', '');
    final renderDataJson = json.decode(str);
    return renderDataJson['state'];
  }

  Future<Map> _getRoomDataByApi(String webRid) async {
    const serverUrl = 'https://live.douyin.com/webcast/room/web/enter/';
    final requestHeader = await getRequestHeaders();
    requestHeader['Referer'] = 'https://live.douyin.com/$webRid';

    final uri = Uri.parse(serverUrl).replace(queryParameters: {
      'aid': '6383',
      'app_name': 'douyin_web',
      'live_id': '1',
      'device_platform': 'web',
      'language': 'zh-CN',
      'browser_language': 'zh-CN',
      'browser_platform': 'Win32',
      'browser_name': 'Chrome',
      'browser_version': '125.0.0.0',
      'web_rid': webRid,
      'msToken': '',
    });
    final requestUrl = DouyinSign.getAbogusUrl(uri.toString(), kDefaultUserAgent);

    final result = await HttpClient.instance.getJson(
      requestUrl,
      header: requestHeader,
    );

    if (result is! Map) throw Exception('抖音接口返回格式异常');
    return result['data'];
  }

  Future<Map> _getRoomDataByRoomId(String roomId) async {
    final result = await HttpClient.instance.getJson(
      'https://webcast.amemv.com/webcast/room/reflow/info/',
      queryParameters: {
        'type_id': 0,
        'live_id': 1,
        'room_id': roomId,
        'sec_user_id': '',
        'version_code': '99.99.99',
        'app_id': 6383,
      },
      header: await getRequestHeaders(),
    );
    return result;
  }

  Future<String> _getWebCookie(String webRid) async {
    final headResp = await HttpClient.instance.head(
      'https://live.douyin.com/$webRid',
      header: headers,
    );
    var dyCookie = '';
    headResp.headers['set-cookie']?.forEach((element) {
      final cookie = element.split(';')[0];
      if (cookie.contains('ttwid')) dyCookie += '$cookie;';
      if (cookie.contains('__ac_nonce')) dyCookie += '$cookie;';
      if (cookie.contains('msToken')) dyCookie += '$cookie;';
    });
    return dyCookie;
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites(
      {required LiveRoomDetail detail}) async {
    final List<LivePlayQuality> qualities = [];

    try {
      final liveCoreData = detail.data['live_core_sdk_data'];
      if (liveCoreData == null) return qualities;

      final pullData = liveCoreData['pull_data'];
      if (pullData == null) return qualities;

      final options = pullData['options'];
      final qulityList = options?['qualities'];
      final streamData = pullData['stream_data']?.toString() ?? '';

      if (!streamData.startsWith('{')) {
        final flvList =
            (detail.data['flv_pull_url'] as Map).values.cast<String>().toList();
        final hlsList =
            (detail.data['hls_pull_url_map'] as Map).values.cast<String>().toList();
        for (final quality in qulityList) {
          final level = quality['level'] as int;
          final List<String> urls = [];
          final flvIndex = flvList.length - level;
          if (flvIndex >= 0 && flvIndex < flvList.length) {
            urls.add(flvList[flvIndex]);
          }
          final hlsIndex = hlsList.length - level;
          if (hlsIndex >= 0 && hlsIndex < hlsList.length) {
            urls.add(hlsList[hlsIndex]);
          }
          if (urls.isNotEmpty) {
            qualities.add(LivePlayQuality(
              quality: quality['name'],
              sort: level,
              data: urls,
            ));
          }
        }
      } else {
        final qualityData = json.decode(streamData)['data'] as Map;
        for (final quality in qulityList) {
          final List<String> urls = [];
          final flvUrl =
              qualityData[quality['sdk_key']]?['main']?['flv']?.toString();
          if (flvUrl != null && flvUrl.isNotEmpty) urls.add(flvUrl);
          final hlsUrl =
              qualityData[quality['sdk_key']]?['main']?['hls']?.toString();
          if (hlsUrl != null && hlsUrl.isNotEmpty) urls.add(hlsUrl);
          if (urls.isNotEmpty) {
            qualities.add(LivePlayQuality(
              quality: quality['name'],
              sort: quality['level'],
              data: urls,
            ));
          }
        }
      }
    } catch (e, stackTrace) {
      CoreLog.error(e);
      CoreLog.error(stackTrace);
    }

    qualities.sort((a, b) => b.sort.compareTo(a.sort));
    return qualities;
  }

  @override
  Future<LivePlayUrl> getPlayUrls(
      {required LiveRoomDetail detail,
      required LivePlayQuality quality}) async {
    return LivePlayUrl(urls: List<String>.from(quality.data));
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword,
      {int page = 1}) async {
    const serverUrl = 'https://www.douyin.com/aweme/v1/web/live/search/';
    final uri = Uri.parse(serverUrl).replace(queryParameters: {
      'device_platform': 'webapp',
      'aid': '6383',
      'channel': 'channel_pc_web',
      'search_channel': 'aweme_live',
      'keyword': keyword,
      'search_source': 'switch_tab',
      'query_correct_type': '1',
      'is_filter_search': '0',
      'from_group_id': '',
      'offset': ((page - 1) * 10).toString(),
      'count': '10',
      'pc_client_type': '1',
      'version_code': '170400',
      'version_name': '17.4.0',
      'cookie_enabled': 'true',
      'screen_width': '1980',
      'screen_height': '1080',
      'browser_language': 'zh-CN',
      'browser_platform': 'Win32',
      'browser_name': 'Edge',
      'browser_version': '125.0.0.0',
      'browser_online': 'true',
      'engine_name': 'Blink',
      'engine_version': '125.0.0.0',
      'os_name': 'Windows',
      'os_version': '10',
      'cpu_core_num': '12',
      'device_memory': '8',
      'platform': 'PC',
      'downlink': '10',
      'effective_type': '4g',
      'round_trip_time': '100',
      'webid': '7382872326016435738',
    });

    final headResp = await HttpClient.instance.head(
      'https://live.douyin.com',
      header: headers,
    );
    var dyCookie = '';
    headResp.headers['set-cookie']?.forEach((element) {
      final cookie = element.split(';')[0];
      if (cookie.contains('ttwid')) dyCookie += '$cookie;';
      if (cookie.contains('__ac_nonce')) dyCookie += '$cookie;';
    });

    final result = await HttpClient.instance.getJson(
      uri.toString(),
      header: {
        'Authority': 'www.douyin.com',
        'accept': 'application/json, text/plain, */*',
        'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'cookie': dyCookie,
        'priority': 'u=1, i',
        'referer':
            'https://www.douyin.com/search/${Uri.encodeComponent(keyword)}?type=live',
        'sec-ch-ua':
            '"Microsoft Edge";v="125", "Chromium";v="125", "Not.A/Brand";v="24"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-origin',
        'user-agent': kDefaultUserAgent,
      },
    );
    if (result == '' || result == 'blocked') {
      throw Exception('抖音直播搜索被限制，请稍后再试');
    }
    final items = <LiveRoomItem>[];
    for (final item in result['data'] ?? []) {
      final itemData = json.decode(item['lives']['rawdata'].toString());
      items.add(LiveRoomItem(
        roomId: itemData['owner']['web_rid'].toString(),
        title: itemData['title'].toString(),
        cover: itemData['cover']['url_list'][0].toString(),
        userName: itemData['owner']['nickname'].toString(),
        online: int.tryParse(itemData['stats']['total_user'].toString()) ?? 0,
      ));
    }
    return LiveSearchRoomResult(hasMore: items.length >= 10, items: items);
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword,
      {int page = 1}) async {
    throw Exception('抖音暂不支持搜索主播，请直接搜索直播间');
  }

  @override
  Future<bool> getLiveStatus({required String roomId}) async {
    final result = await getRoomDetail(roomId: roomId);
    return result.status;
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage(
      {required String roomId}) {
    return Future.value([]);
  }

  int _generateRandomNumber(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(10));
    final buffer = StringBuffer();
    for (final item in values) {
      buffer.write(item);
    }
    return int.tryParse(buffer.toString()) ?? Random().nextInt(1000000000);
  }
}
