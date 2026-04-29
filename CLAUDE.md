# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

OneLive — 跨平台直播聚合应用，聚合 B站/斗鱼/虎牙/抖音四平台，目标平台 Windows x64 + Android ARMv8。Flutter/Dart 开发，Clean Architecture + Feature-first 架构。

参考项目（在 `../` 目录下，只读参考，不修改）：
- `dart_simple_live` — Flutter 项目，完整的 pure Dart 核心库，最重要参考
- `dtv` — Tauri 2.0 (Rust) + Next.js 桌面端
- `dtv_mobile` — KMP + Jetpack Compose Android 端

## 常用命令

```bash
# 安装依赖
flutter pub get
cd simple_live_core && dart pub get && cd ..

# media_kit 原生库设置 (flutter clean 之后、构建之前必须运行)
bash .media_kit_libs/setup.sh

# 代码生成 (freezed, json_serializable, drift, riverpod)
dart run build_runner build -d

# 代码生成 (watch 模式)
dart run build_runner watch -d

# 静态分析
flutter analyze
cd simple_live_core && dart analyze && cd ..

# 运行测试
flutter test
cd simple_live_core && dart test && cd ..

# 运行应用
flutter run -d windows
flutter run -d android

# 构建
flutter build windows
flutter build appbundle --target-platform android-arm64
```

### media_kit 原生库说明

防火墙阻止 GitHub HTTPS，media_kit 的原生库（MPV/ANGLE）无法在构建时自动下载。
已将所需文件预置在 `.media_kit_libs/` 中，每次 `flutter clean` 后需运行 `bash .media_kit_libs/setup.sh` 将归档复制到构建目录。

- Windows: `mpv-dev-x86_64-20230924-git-652a1dd.7z` + `ANGLE.7z` → `build/windows/x64/`
- Android: `default-arm64-v8a.jar` → `build/media_kit_libs_android_video/v1.1.7/`

## 架构总览

```
onelive/
├── simple_live_core/           # 纯 Dart 核心库，与 Flutter UI 零依赖
│   └── lib/src/
│       ├── interface/          # LiveSite / LiveDanmaku 抽象基类
│       ├── model/              # 数据模型 (LiveRoomItem, LiveMessage, ...)
│       ├── common/             # HttpClient(Dio) / WebSocketUtil(心跳+重连) / BinaryReader&Writer
│       ├── platform/           # 各平台 LiveSite 实现 (bilibili_site, ...)
│       └── danmaku/            # 各平台弹幕客户端 (bilibili_danmaku, ...)
└── lib/
    ├── core/
    │   ├── api/                # DioClient 单例 + ApiException
    │   ├── database/           # Drift 数据库 (FavoriteRooms, WatchHistory)
    │   ├── router/             # GoRouter + StatefulShellRoute (4 Tab 布局)
    │   ├── theme/              # Material 3 亮色/暗色主题
    │   └── utils/              # 平台检测
    └── features/
        ├── live/               # 直播浏览 (SiteRegistry → Riverpod → StreamGrid)
        ├── player/             # 播放器 (阶段 3 接入 media_kit)
        ├── danmaku/            # 弹幕覆盖层 (阶段 4 自研 CustomPainter)
        ├── favorites/          # 收藏与历史 (阶段 6 ✅)
        ├── search/             # 搜索 (阶段 7)
        └── settings/           # 设置 (阶段 8)
```

**核心设计决策**：
- simple_live_core 为纯 Dart 包，不依赖 Flutter，未来可被任何 Dart 项目复用
- 四平台各自实现 LiveSite 子类，通过 SiteRegistry 注册
- Riverpod 作为状态管理和 DI 容器：`ref.watch(provider)` 响应式更新 UI
- 错误处理用 fpdart TaskEither，单平台 API 失败不级联崩溃

## 实现顺序

B站(低难度) → 斗鱼(中) → 虎牙(中) → 抖音(高)，每个平台先 API 后弹幕。参考 `dart_simple_live/simple_live_core/lib/src/` 下各平台 site 和 danmaku 实现。

**关键参考文件**：
- B站: `../dart_simple_live/simple_live_core/lib/src/bilibili_site.dart`
- 斗鱼: `../dart_simple_live/simple_live_core/lib/src/douyu_site.dart`
- 虎牙: `../dart_simple_live/simple_live_core/lib/src/huya_site.dart`
- 抖音: `../dart_simple_live/simple_live_core/lib/src/douyin_site.dart`

## 已实现平台

### B站 (bilibili)
- 站点: `simple_live_core/lib/src/platform/bilibili_site.dart` — WBI 签名、推荐列表、分类浏览、搜索、房间详情、流地址获取
- 弹幕: `simple_live_core/lib/src/danmaku/bilibili_danmaku.dart` — WebSocket 二进制帧协议、Brotli 解压、JSON 解析
- 注册: `main.dart` 中 `SiteRegistry.register(BiliBiliSite())`

### 斗鱼 (douyu)
- 站点: `simple_live_core/lib/src/platform/douyu_site.dart` — 分类列表、推荐、房间详情(betard+homeH5Enc)、流地址获取(getH5Play)、搜索
- 弹幕: `simple_live_core/lib/src/danmaku/douyu_danmaku.dart` — WebSocket 自定义二进制帧、STT key-value 编码解析
- 签名: `simple_live_core/lib/src/scripts/douyu_sign.dart` — dart_quickjs + CryptoJS (ub98484234)
- 注册: `main.dart` 中 `SiteRegistry.register(DouyuSite())`

### 虎牙 (huya)
- 站点: `simple_live_core/lib/src/platform/huya_site.dart` — 页面解析(HNF_GLOBAL_INIT)、分类列表、推荐、房间详情、TARS WUP 端点、buildAntiCode 防盗链
- 弹幕: `simple_live_core/lib/src/danmaku/huya_danmaku.dart` — WebSocket TARS 二进制帧、HYPushMessage/HYMessage 解析
- 依赖: `simple_live_core/packages/tars_dart/` — TARS 编解码库
- 注册: `main.dart` 中 `SiteRegistry.register(HuyaSite())`

### 抖音 (douyin)
- 站点: `simple_live_core/lib/src/platform/douyin_site.dart` — 分类列表、推荐(abogus签名)、房间详情(webRid/roomId双模式)、流地址解析、搜索
- 弹幕: `simple_live_core/lib/src/danmaku/douyin_danmaku.dart` — WebSocket Protobuf (PushFrame/Response/ChatMessage)、gzip 解压
- 签名: `simple_live_core/lib/src/scripts/douyin_sign.dart` — dart_quickjs (abogus + webmssdk)
- 弹幕 Proto: `simple_live_core/lib/src/danmaku/proto/douyin.pb.dart`
- 注册: `main.dart` 中 `SiteRegistry.register(DouyinSite())`

## 四平台技术要点

| 平台 | 流协议 | 弹幕协议 | 签名方式 | 难度 |
|------|--------|---------|---------|------|
| B站 | HLS/FLV | WebSocket → Brotli → JSON | WBI (img_key+sub_key→md5) | 低 |
| 斗鱼 | FLV | WebSocket → 自定义二进制帧 → STT key-value | JS 加密 (dart_quickjs) | 中 |
| 虎牙 | HLS/FLV | WebSocket → TARS 二进制帧 | TARS (WUP 端点) + MD5 | 中 |
| 抖音 | HLS/FLV | WebSocket → Protobuf → gzip | abogus (SM3+RC4) | 高 |

## 收藏与历史 (阶段 6 ✅)

- **数据库**: `$AppDatabaseManager.favoriteRooms` 和 `watchHistory` 表管理器
- **Repository**: `lib/features/favorites/data/favorite_repository.dart` — Drift DAO 封装
- **Providers**: `lib/features/favorites/presentation/providers/favorites_providers.dart`
  - `favoritesProvider` — StreamProvider 响应式收藏列表
  - `watchHistoryProvider` — StreamProvider 响应式历史列表
  - `isFavoriteProvider` — FutureProvider.family 单个房间收藏状态
- **UI**: `FavoritesPage` 双 Tab（收藏网格 + 历史列表），点击跳转播放器
- **收藏按钮**: StreamCard 右上角 + PlayerPage 顶部栏
- **自动记录**: 进入 PlayerPage 时自动写入 `WatchHistory` 表

## 跨平台搜索 (阶段 7 ✅)

- **Providers**: `lib/features/search/presentation/providers/search_providers.dart`
  - `searchKeywordProvider` — StateProvider 已提交的搜索关键词
  - `searchModeProvider` — StateProvider 搜索模式（0=直播间，1=主播）
  - `searchRoomsProvider` — FutureProvider.autoDispose.family(keyword+platform) 直播间搜索
  - `searchAnchorsProvider` — FutureProvider.autoDispose.family(keyword+platform) 主播搜索
- **核心 API**: 各平台 `LiveSite.searchRooms()` / `searchAnchors()` 方法
- **UI**: `SearchPage` — ConsumerStatefulWidget，TabController 驱动四平台 Tab
  - 搜索框 + 模式切换下拉（直播间/主播）
  - 平台 Tab 栏（B站/斗鱼/虎牙/抖音）
  - 直播间模式复用 `StreamGrid` 组件
  - 主播模式显示头像 + 名称 + 直播状态列表

## 注意事项

- 不要修改 `../` 目录下的 dart_simple_live / dtv / dtv_mobile 参考项目
- 新平台接入：在 `simple_live_core` 中创建 `xxx_site.dart` 和 `danmaku/xxx_danmaku.dart`，然后在 `SiteRegistry` 注册
- Drift 数据库模型变更后需要运行 `dart run build_runner build -d` 重新生成
- Windows 端窗口管理使用 `window_manager` 包；Android 端全屏使用 `SystemChrome`
