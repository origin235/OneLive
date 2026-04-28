# OneLive

跨平台直播聚合应用，聚合 B站/斗鱼/虎牙/抖音四平台直播，支持 Windows x64 和 Android ARMv8。

## 平台支持

| 平台 | 直播列表 | 播放 | 弹幕 | 搜索 |
|------|---------|------|------|------|
| B站 | 计划中 | 计划中 | 计划中 | 计划中 |
| 斗鱼 | 计划中 | 计划中 | 计划中 | 计划中 |
| 虎牙 | 计划中 | 计划中 | 计划中 | 计划中 |
| 抖音 | 计划中 | 计划中 | 计划中 | 计划中 |

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
├── simple_live_core/        # 纯 Dart 核心库（与 Flutter UI 解耦）
│   └── lib/src/
│       ├── interface/       # LiveSite / LiveDanmaku 抽象接口
│       ├── model/           # 数据模型
│       └── common/          # HTTP/WebSocket 通用工具
└── lib/
    ├── core/                # 基础设施 (API/DB/Router/Theme)
    └── features/            # 功能模块 (live/player/danmaku/favorites/search/settings)
```

## 环境要求

- Flutter SDK >= 3.4.0
- Dart SDK >= 3.4.0
- Windows: Visual Studio 2022 (Desktop development with C++)
- Android: Android SDK + NDK

## 快速开始

```bash
# 1. 克隆项目
cd onelive

# 2. 安装依赖
flutter pub get
cd simple_live_core && dart pub get && cd ..

# 3. 生成代码
dart run build_runner build -d

# 4. 运行
flutter run -d windows   # Windows
flutter run -d android   # Android

# 5. 测试
flutter test
cd simple_live_core && dart test && cd ..
```

## 开发进度

- [x] 阶段 1：项目脚手架
- [ ] 阶段 2：B站集成 + 直播列表
- [ ] 阶段 3：播放器 (media_kit)
- [ ] 阶段 4：弹幕覆盖层
- [ ] 阶段 5：多平台扩展（斗鱼/虎牙/抖音）
- [ ] 阶段 6：收藏与历史
- [ ] 阶段 7：跨平台搜索
- [ ] 阶段 8：设置与打磨
- [ ] 阶段 9：测试与发布

## 免责声明

本项目仅用于学习交流编程技术。所有直播内容版权归属各平台。请勿用于商业目的。
