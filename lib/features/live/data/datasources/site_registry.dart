import 'package:simple_live_core/simple_live_core.dart';

/// 平台站点注册表 —— 维护所有可用直播平台的 LiveSite 实例
class SiteRegistry {
  static final Map<String, LiveSite> _sites = {};

  static void register(LiveSite site) {
    _sites[site.id] = site;
  }

  static LiveSite? get(String id) => _sites[id];

  static List<LiveSite> get all => _sites.values.toList();

  static List<String> get ids => _sites.keys.toList();
}
