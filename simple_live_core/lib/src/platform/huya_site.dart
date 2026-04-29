import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../common/http_client.dart';
import '../danmaku/huya_danmaku.dart';
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
import '../model/tars/get_cdn_token_ex_req.dart';
import '../model/tars/get_cdn_token_ex_resp.dart';
import '../model/tars/huya_user_id.dart';
import 'package:tars_dart/tars/net/base_tars_http.dart';

class HuyaSite extends LiveSite {
  static const baseUrl = 'https://m.huya.com/';
  static const kUserAgent =
      'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36 Edg/117.0.0.0';
  static const HYSDK_UA =
      'HYSDK(Windows, 30000002)_APP(pc_exe&7060000&official)_SDK(trans&2.32.3.5646)';

  static final Map<String, String> requestHeaders = {
    'Origin': baseUrl,
    'Referer': baseUrl,
    'User-Agent': HYSDK_UA,
  };

  late final BaseTarsHttp tupClient =
      BaseTarsHttp('http://wup.huya.com', 'liveui', headers: requestHeaders);

  HuyaSite() {
    id = 'huya';
    name = '虎牙直播';
  }

  @override
  LiveDanmaku getDanmaku() => HuyaDanmaku();

  @override
  Future<List<LiveCategory>> getCategores() async {
    final List<LiveCategory> categories = [
      LiveCategory(id: '1', name: '网游', children: []),
      LiveCategory(id: '2', name: '单机', children: []),
      LiveCategory(id: '8', name: '娱乐', children: []),
      LiveCategory(id: '3', name: '手游', children: []),
    ];
    for (final item in categories) {
      final items = await _getSubCategores(item.id);
      item.children.addAll(items);
    }
    return categories;
  }

  Future<List<LiveSubCategory>> _getSubCategores(String id) async {
    final result = await HttpClient.instance.getJson(
      'https://live.cdn.huya.com/liveconfig/game/bussLive',
      queryParameters: {'bussType': id},
    );
    final List<LiveSubCategory> subs = [];
    for (final item in result['data']) {
      String gid;
      if (item['gid'] is Map) {
        gid = item['gid']['value'].toString().split(',').first;
      } else if (item['gid'] is double) {
        gid = item['gid'].toInt().toString();
      } else if (item['gid'] is int) {
        gid = item['gid'].toString();
      } else {
        gid = item['gid'].toString();
      }
      subs.add(LiveSubCategory(
        id: gid,
        name: item['gameFullName'].toString(),
        parentId: id,
        pic: 'https://huyaimg.msstatic.com/cdnimage/game/$gid-MS.jpg',
      ));
    }
    return subs;
  }

  @override
  Future<LiveCategoryResult> getCategoryRooms(LiveSubCategory category,
      {int page = 1}) async {
    final resultText = await HttpClient.instance.getJson(
      'https://www.huya.com/cache.php',
      queryParameters: {
        'm': 'LiveList',
        'do': 'getLiveListByPage',
        'tagAll': 0,
        'gameId': category.id,
        'page': page,
      },
    );
    final result = json.decode(resultText);
    final items = <LiveRoomItem>[];
    for (final item in result['data']['datas']) {
      var cover = item['screenshot'].toString();
      if (!cover.contains('?')) cover += '?x-oss-process=style/w338_h190&';
      var title = item['introduction']?.toString() ?? '';
      if (title.isEmpty) title = item['roomName']?.toString() ?? '';
      items.add(LiveRoomItem(
        roomId: item['profileRoom'].toString(),
        title: title,
        cover: cover,
        userName: item['nick'].toString(),
        online: int.tryParse(item['totalCount'].toString()) ?? 0,
      ));
    }
    final hasMore = result['data']['page'] < result['data']['totalPage'];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveCategoryResult> getRecommendRooms({int page = 1}) async {
    final resultText = await HttpClient.instance.getJson(
      'https://www.huya.com/cache.php',
      queryParameters: {
        'm': 'LiveList',
        'do': 'getLiveListByPage',
        'tagAll': 0,
        'page': page,
      },
    );
    final result = json.decode(resultText);
    final items = <LiveRoomItem>[];
    for (final item in result['data']['datas']) {
      var cover = item['screenshot'].toString();
      if (!cover.contains('?')) cover += '?x-oss-process=style/w338_h190&';
      var title = item['introduction']?.toString() ?? '';
      if (title.isEmpty) title = item['roomName']?.toString() ?? '';
      items.add(LiveRoomItem(
        roomId: item['profileRoom'].toString(),
        title: title,
        cover: cover,
        userName: item['nick'].toString(),
        online: int.tryParse(item['totalCount'].toString()) ?? 0,
      ));
    }
    final hasMore = result['data']['page'] < result['data']['totalPage'];
    return LiveCategoryResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveRoomDetail> getRoomDetail({required String roomId}) async {
    final roomInfo = await _getRoomInfo(roomId);
    final tLiveInfo = roomInfo['roomInfo']['tLiveInfo'];
    final tProfileInfo = roomInfo['roomInfo']['tProfileInfo'];

    var title = tLiveInfo['sIntroduction']?.toString() ?? '';
    if (title.isEmpty) title = tLiveInfo['sRoomName']?.toString() ?? '';

    final huyaLines = <HuyaLineModel>[];
    final huyaBiterates = <HuyaBitRateModel>[];

    final lines = tLiveInfo['tLiveStreamInfo']['vStreamInfo']['value'];
    for (final item in lines) {
      if ((item['sFlvUrl']?.toString() ?? '').isNotEmpty) {
        huyaLines.add(HuyaLineModel(
          line: item['sFlvUrl'].toString(),
          lineType: HuyaLineType.flv,
          flvAntiCode: item['sFlvAntiCode'].toString(),
          hlsAntiCode: item['sHlsAntiCode'].toString(),
          streamName: item['sStreamName'].toString(),
          cdnType: item['sCdnType'].toString(),
          presenterUid: roomInfo['topSid'] ?? 0,
        ));
      }
    }

    final biterates = tLiveInfo['tLiveStreamInfo']['vBitRateInfo']['value'];
    for (final item in biterates) {
      final name = item['sDisplayName'].toString();
      if (name.contains('HDR')) continue;
      huyaBiterates.add(HuyaBitRateModel(
        bitRate: item['iBitRate'],
        name: name,
      ));
    }

    final topSid = roomInfo['topSid'];
    final subSid = roomInfo['subSid'];

    return LiveRoomDetail(
      cover: tLiveInfo['sScreenshot'].toString(),
      online: tLiveInfo['lTotalCount'],
      roomId: tLiveInfo['lProfileRoom'].toString(),
      title: title,
      userName: tProfileInfo['sNick'].toString(),
      userAvatar: tProfileInfo['sAvatar180'].toString(),
      introduction: tLiveInfo['sIntroduction'].toString(),
      notice: roomInfo['welcomeText'].toString(),
      status: roomInfo['roomInfo']['eLiveStatus'] == 2,
      data: HuyaUrlDataModel(
        lines: huyaLines,
        bitRates: huyaBiterates,
      ),
      danmakuData: HuyaDanmakuArgs(
        ayyuid: tLiveInfo['lYyid'] ?? 0,
        topSid: topSid ?? 0,
        subSid: subSid ?? 0,
      ),
      url: 'https://www.huya.com/$roomId',
    );
  }

  Future<Map> _getRoomInfo(String roomId) async {
    final resultText = await HttpClient.instance.getText(
      'https://m.huya.com/$roomId',
      header: {'user-agent': kUserAgent},
    );
    final text = RegExp(
            r'window\.HNF_GLOBAL_INIT.=.\{[\s\S]*?\}[\s\S]*?</script>',
            multiLine: false)
        .firstMatch(resultText)
        ?.group(0);
    final jsonText = text!
        .replaceAll(RegExp(r'window\.HNF_GLOBAL_INIT.=.'), '')
        .replaceAll('</script>', '')
        .replaceAllMapped(
            RegExp(r'function.*?\(.*?\).\{[\s\S]*?\}'), (match) => '""');
    final jsonObj = json.decode(jsonText);
    final topSid = int.tryParse(
        RegExp(r'lChannelId":([0-9]+)').firstMatch(resultText)?.group(1) ??
            '0');
    final subSid = int.tryParse(
        RegExp(r'lSubChannelId":([0-9]+)').firstMatch(resultText)?.group(1) ??
            '0');
    jsonObj['topSid'] = topSid;
    jsonObj['subSid'] = subSid;
    return jsonObj;
  }

  @override
  Future<List<LivePlayQuality>> getPlayQualites(
      {required LiveRoomDetail detail}) {
    final urlData = detail.data as HuyaUrlDataModel;
    final List<LivePlayQuality> qualities = [];
    if (urlData.bitRates.isEmpty) {
      urlData.bitRates = [
        HuyaBitRateModel(name: '原画', bitRate: 0),
        HuyaBitRateModel(name: '高清', bitRate: 2000),
      ];
    }
    for (final item in urlData.bitRates) {
      qualities.add(LivePlayQuality(
        data: {'urls': urlData.lines, 'bitRate': item.bitRate},
        quality: item.name,
      ));
    }
    return Future.value(qualities);
  }

  @override
  Future<LivePlayUrl> getPlayUrls(
      {required LiveRoomDetail detail,
      required LivePlayQuality quality}) async {
    final ls = <String>[];
    for (final element in quality.data['urls']) {
      final line = element as HuyaLineModel;
      final url = await _getPlayUrl(line, quality.data['bitRate']);
      ls.add(url);
    }
    return LivePlayUrl(
      urls: ls,
      headers: {'user-agent': HYSDK_UA},
    );
  }

  Future<String> _getPlayUrl(HuyaLineModel line, int bitRate) async {
    var antiCode =
        await _getCndTokenInfoEx(line.streamName);
    antiCode = buildAntiCode(line.streamName, line.presenterUid, antiCode);
    var url = '${line.line}/${line.streamName}.flv?${antiCode}&codec=264';
    if (bitRate > 0) url += '&ratio=$bitRate';
    return url;
  }

  String buildAntiCode(String stream, int presenterUid, String antiCode) {
    final mapAnti = Uri(query: antiCode).queryParametersAll;
    if (!mapAnti.containsKey('fm')) return antiCode;

    final ctype = mapAnti['ctype']?.first ?? 'huya_pc_exe';
    final platformId = int.tryParse(mapAnti['t']?.first ?? '0');
    final clacStartTime = DateTime.now().millisecondsSinceEpoch;

    final seqId = presenterUid + clacStartTime;
    final secretHash =
        md5.convert(utf8.encode('$seqId|$ctype|$platformId')).toString();

    final convertUid = rotl64(presenterUid);
    final calcUid = platformId == 103 ? presenterUid : convertUid;
    final fm = Uri.decodeComponent(mapAnti['fm']!.first);
    final secretPrefix = utf8.decode(base64.decode(fm)).split('_').first;
    var wsTime = mapAnti['wsTime']!.first;
    final secretStr =
        '${secretPrefix}_${calcUid}_${stream}_${secretHash}_$wsTime';
    final wsSecret = md5.convert(utf8.encode(secretStr)).toString();

    final rnd = Random();
    final ct =
        ((int.parse(wsTime, radix: 16) + rnd.nextDouble()) * 1000).toInt();
    final Map<String, dynamic> antiCodeRes = {
      'wsSecret': wsSecret,
      'wsTime': wsTime,
      'seqid': seqId,
      'ctype': ctype,
      'ver': '1',
      'fs': mapAnti['fs']!.first,
      'fm': Uri.encodeComponent(mapAnti['fm']!.first),
      't': platformId,
    };
    if (platformId == 103) {
      antiCodeRes['uid'] = presenterUid;
      antiCodeRes['uuid'] =
          (((ct % 1e10) + rnd.nextDouble()) * 1e3 % 0xffffffff).toInt().toString();
    } else {
      antiCodeRes['u'] = convertUid;
    }
    return antiCodeRes.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Future<String> _getCndTokenInfoEx(String stream) async {
    final func = 'getCdnTokenInfoEx';
    final tid = HuyaUserId();
    tid.sHuYaUA = 'pc_exe&7060000&official';
    final tReq = GetCdnTokenExReq();
    tReq.tId = tid;
    tReq.sStreamName = stream;
    final resp = await tupClient.tupRequest(func, tReq, GetCdnTokenExResp());
    return resp.sFlvToken;
  }

  int rotl64(int t) {
    final low = t & 0xFFFFFFFF;
    final rotatedLow = ((low << 8) | (low >> 24)) & 0xFFFFFFFF;
    final high = t & ~0xFFFFFFFF;
    return high | rotatedLow;
  }

  @override
  Future<LiveSearchRoomResult> searchRooms(String keyword,
      {int page = 1}) async {
    final resultText = await HttpClient.instance.getJson(
      'https://search.cdn.huya.com/',
      queryParameters: {
        'm': 'Search',
        'do': 'getSearchContent',
        'q': keyword,
        'uid': 0,
        'v': 4,
        'typ': -5,
        'livestate': 0,
        'rows': 20,
        'start': (page - 1) * 20,
      },
    );
    final result = json.decode(resultText);
    final items = <LiveRoomItem>[];
    for (final item in result['response']['3']['docs']) {
      var cover = item['game_screenshot'].toString();
      if (!cover.contains('?')) cover += '?x-oss-process=style/w338_h190&';
      var title = item['game_introduction']?.toString() ?? '';
      if (title.isEmpty) title = item['game_roomName']?.toString() ?? '';
      items.add(LiveRoomItem(
        roomId: item['room_id'].toString(),
        title: title,
        cover: cover,
        userName: item['game_nick'].toString(),
        online: int.tryParse(item['game_total_count'].toString()) ?? 0,
      ));
    }
    final hasMore = result['response']['3']['numFound'] > (page * 20);
    return LiveSearchRoomResult(hasMore: hasMore, items: items);
  }

  @override
  Future<LiveSearchAnchorResult> searchAnchors(String keyword,
      {int page = 1}) async {
    final resultText = await HttpClient.instance.getJson(
      'https://search.cdn.huya.com/',
      queryParameters: {
        'm': 'Search',
        'do': 'getSearchContent',
        'q': keyword,
        'uid': 0,
        'v': 1,
        'typ': -5,
        'livestate': 0,
        'rows': 20,
        'start': (page - 1) * 20,
      },
    );
    final result = json.decode(resultText);
    final items = <LiveAnchorItem>[];
    for (final item in result['response']['1']['docs']) {
      items.add(LiveAnchorItem(
        roomId: item['room_id'].toString(),
        avatar: item['game_avatarUrl180'].toString(),
        userName: item['game_nick'].toString(),
        liveStatus: item['gameLiveOn'],
      ));
    }
    final hasMore = result['response']['1']['numFound'] > (page * 20);
    return LiveSearchAnchorResult(hasMore: hasMore, items: items);
  }

  @override
  Future<bool> getLiveStatus({required String roomId}) async {
    final roomInfo = await _getRoomInfo(roomId);
    return roomInfo['roomInfo']['eLiveStatus'] == 2;
  }

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage(
      {required String roomId}) {
    return Future.value([]);
  }
}

class HuyaUrlDataModel {
  final List<HuyaLineModel> lines;
  List<HuyaBitRateModel> bitRates;

  HuyaUrlDataModel({
    required this.bitRates,
    required this.lines,
  });
}

enum HuyaLineType { flv, hls }

class HuyaLineModel {
  final String line;
  final String cdnType;
  final String flvAntiCode;
  final String hlsAntiCode;
  final String streamName;
  final HuyaLineType lineType;
  final int presenterUid;

  HuyaLineModel({
    required this.line,
    required this.lineType,
    required this.flvAntiCode,
    required this.hlsAntiCode,
    required this.streamName,
    required this.cdnType,
    required this.presenterUid,
  });
}

class HuyaBitRateModel {
  final String name;
  final int bitRate;

  HuyaBitRateModel({
    required this.bitRate,
    required this.name,
  });
}
