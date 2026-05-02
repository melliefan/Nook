# Nook · 角落

macOS 原生热角待办面板，Swift + SwiftUI + AppKit。

## 技术栈

- **Swift 6.1** + SwiftUI + AppKit（不再使用 Electron）
- 热角检测：CGEvent tap（需辅助功能权限），无权限时降级为 NSEvent 轮询
- 面板：NSPanel 子类（NookPanel），透明无边框，始终置顶
- 持久化：JSON 文件 `~/Library/Application Support/Nook/data/tasks.json`
- 数据格式与旧版 Electron 完全兼容

## 项目结构

Swift 源码在 `NookSwift/` 目录：

```
NookSwift/
├── build.sh                  # 构建脚本（先跑测试再编译）
├── project.yml               # xcodegen 配置
├── Nook/
│   ├── App/                  # 入口 + AppDelegate
│   ├── Core/                 # Store、PanelController、HotCornerManager
│   ├── Models/               # NookTask、Snippet、NookSettings
│   ├── Views/                # 全部 SwiftUI 视图
│   └── Resources/            # Info.plist、entitlements、Assets
└── Tests/                    # 单元测试（360+ 用例）
```

旧版 Electron 代码在根目录 `src/`，保留但不再维护。

## 构建 & 运行

```bash
cd NookSwift
bash build.sh              # 跑测试 + 编译（产物: build/Nook.app, ~1.6MB）
bash build.sh --skip-tests # 跳过测试直接编译
./build/Nook.app/Contents/MacOS/Nook  # 启动
```

## 开发注意

- 所有代码改动后必须确保 `bash build.sh` 测试全过再交付
- Store 是 `@MainActor`，测试中用 `await MainActor.run {}` 包裹
- NSPanel 需要 `canBecomeKey = true` 才能让 SwiftUI TextField 获取焦点
- 隐藏逻辑用 Timer 驱动（鼠标离开 0.5s 后收起），不依赖鼠标移动事件
