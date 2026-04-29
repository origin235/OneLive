# OneLive

跨平台直播聚合应用，聚合 B站/斗鱼/虎牙/抖音四平台直播，支持 Windows x64 和 Android ARMv8。

## 平台支持

| 平台 | 直播列表 | 播放 | 弹幕 | 搜索 |
|------|---------|------|------|------|
| B站 | ✅ | ✅ | ✅ | ✅ |
| 斗鱼 | ✅ | ✅ | ✅ | ✅ |
| 虎牙 | ✅ | ✅ | ✅ | ✅ |
| 抖音 | ✅ | ✅ | ✅ | ✅ |

## 技术栈

- **框架**: Flutter/Dart（一套代码编译 Windows + Android）
- **状态管理**: Riverpod 2.x
- **架构**: Clean Architecture + Feature-first
- **HTTP**: Dio
- **视频播放**: media_kit（FFmpeg/mpv）
- **弹幕渲染**: 自研 CustomPainter
- **本地存储**: Drift (SQLite)
- **路由**: go_router

## 项目结构

```
onelive/
├── simple_live_core/          # 纯 Dart 核心库（与 Flutter UI 解耦）
│   └── lib/src/
│       ├── interface/         # LiveSite / LiveDanmaku 抽象接口
│       ├── model/             # 数据模型
│       ├── common/            # HTTP/WebSocket 通用工具
│       ├── platform/          # 四平台 LiveSite 实现
│       └── danmaku/           # 四平台弹幕客户端
└── lib/
    ├── core/
    │   ├── api/               # Dio 实例、自定义异常
    │   ├── database/          # Drift 数据库 (收藏+历史)
    │   ├── router/            # GoRouter + 4 Tab 布局
    │   └── theme/             # Material 3 亮色/暗色主题
    └── features/
        ├── live/              # 直播浏览与发现
        ├── player/            # 直播播放器
        ├── danmaku/           # 弹幕覆盖层
        ├── favorites/         # 收藏与历史
        ├── search/            # 跨平台搜索
        └── settings/          # 应用设置
```

## 环境要求

- Flutter SDK >= 3.4.0
- Dart SDK >= 3.4.0
- Windows: Visual Studio 2022 (Desktop development with C++)
- Android: Android SDK + NDK

## 快速开始

```bash
# 1. 安装依赖
flutter pub get
cd simple_live_core && dart pub get && cd ..

# 2. media_kit 原生库设置（flutter clean 后必须运行）
bash .media_kit_libs/setup.sh

# 3. 生成代码
dart run build_runner build -d

# 4. 运行
flutter run -d windows   # Windows
flutter run -d android   # Android

# 5. 测试与分析
flutter analyze
flutter test
cd simple_live_core && dart analyze && dart test && cd ..
```

## 开发进度

- [x] 阶段 1：项目脚手架
- [x] 阶段 2：B站集成 + 直播列表
- [x] 阶段 3：播放器 (media_kit)
- [x] 阶段 4：弹幕覆盖层
- [x] 阶段 5：多平台扩展（斗鱼/虎牙/抖音）
- [x] 阶段 6：收藏与历史
- [x] 阶段 7：跨平台搜索
- [x] 阶段 8：设置与打磨
- [ ] 阶段 9：测试与发布

## 免责声明

本项目仅用于学习交流编程技术。所有直播内容版权归属各平台。请勿用于商业目的。
