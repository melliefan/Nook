# Nook Swift 项目交接文档

## 项目概述

Nook（角落）是一个 macOS 原生热角待办面板，从 Electron 迁移到 Swift/SwiftUI/AppKit。用户把鼠标滑到屏幕角落即弹出面板，移开自动收起。

## 当前状态

### 已完成
- Swift 6.1 + SwiftUI + AppKit 基础架构
- 热角检测（CGEvent tap + 回退轮询）
- NSPanel 浮动面板（canBecomeKey, 支持输入）
- 数据持久化（JSON，与旧版 Electron 格式兼容）
- 360 个单元测试全部通过
- 编译产物 1.9MB（vs Electron 103MB）

### 功能清单
| 功能 | 状态 | 说明 |
|---|---|---|
| 任务 CRUD | ✅ | 添加/编辑/删除/完成 |
| 子任务 | ✅ | 内联展开/勾选/添加/删除 |
| 子任务全完成→父任务自动完成 | ✅ | Store.toggleSubtask 里实现 |
| 标签系统 | ✅ | 20色盘，自动分配颜色 |
| 标签筛选 | ✅ | 点击标签过滤任务 |
| 标签溢出 +N | ✅ | 超8个显示+N，展开/收起 |
| 标签颜色选择 | ⚠️ | 长按弹出颜色选择器，但可能不稳定 |
| 优先级 | ✅ | 高/中/低/无 |
| 截止日期 | ✅ | 今天/明天/下周/自定义 |
| 排序 | ✅ | 自定义/优先级/日期/标题/创建时间 |
| 快捷粘贴 | ✅ | 深色卡片，hover 显示复制/编辑 |
| 设置 | ✅ | 热角位置(四角) + 深浅模式切换 |
| 面板固定 | ✅ | Pin 按钮 |
| 详情编辑页 | ✅ | 从右侧滑入 |
| 深浅模式 | ✅ | 跟随系统 / 手动切换 |
| 全局快捷键 | ✅ | ⌘⇧T |
| 多显示器 | ✅ | 每个屏幕独立触发 |

### 已知 Bug / 待改进
1. **标签颜色选择器交互不稳定** — 长按触发有时不灵，需要更好的交互方式
2. **礼炮特效未实现** — HTML 设计稿有 canvas-confetti 庆祝效果，Swift 版未移植
3. **设计稿与实际 UI 有细节差异** — 字体、间距、图标风格（SF Symbols vs Solar Bold）
4. **面板收起灵敏度** — Timer 驱动的隐藏逻辑，0.5s 延迟后收起
5. **拖拽排序** — Store 有 reorderTask 方法但 UI 没有拖拽手柄

## 项目结构

```
NookSwift/
├── build.sh                  # 构建脚本（先跑测试再编译）
├── build/Nook.app/           # 编译产物
├── project.yml               # xcodegen 配置（需要安装 xcodegen）
├── Nook/
│   ├── App/
│   │   ├── NookApp.swift          # @main 入口
│   │   └── AppDelegate.swift      # NSApplicationDelegate，初始化所有组件
│   ├── Core/
│   │   ├── Store.swift            # @MainActor 数据层，JSON 持久化
│   │   ├── PanelController.swift  # NSPanel 管理，动画，NookPanel 子类
│   │   └── HotCornerManager.swift # CGEvent tap 热角检测
│   ├── Models/
│   │   ├── NookTask.swift         # 任务模型 + Priority 枚举
│   │   ├── Snippet.swift          # 快捷粘贴模型
│   │   └── NookSettings.swift     # 设置模型 + CornerTrigger 枚举
│   ├── Views/
│   │   ├── PanelView.swift        # 主面板容器 + HeaderView + SortMenuView + AttributionView
│   │   ├── TagFilterBarView.swift  # 标签筛选栏 + WrappingHStack + ColorPickerGridView
│   │   ├── AddTaskView.swift      # 添加任务表单
│   │   ├── TaskListView.swift     # 任务列表 + TaskRowView（内联子任务）
│   │   ├── TaskDetailView.swift   # 任务详情编辑页
│   │   ├── SnippetsSectionView.swift # 快捷粘贴区（深色卡片）
│   │   ├── SettingsPopoverView.swift # 设置弹窗
│   │   └── NookTheme.swift        # 设计 token（颜色常量）
│   └── Resources/
│       ├── Info.plist
│       ├── Nook.entitlements
│       └── Assets.xcassets/
└── Tests/
    ├── TestRunner.swift
    ├── ModelTests.swift
    ├── StoreTests.swift
    ├── GeometryTests.swift
    └── EdgeCaseTests.swift
```

## 构建方式

```bash
cd NookSwift
bash build.sh              # 跑测试 + 编译
bash build.sh --skip-tests # 跳过测试
./build/Nook.app/Contents/MacOS/Nook  # 启动
```

无需 Xcode，用 `xcrun swiftc` 直接编译。需要 Command Line Tools。

## 数据文件

`~/Library/Application Support/Nook/data/tasks.json`

格式与旧版 Electron 完全兼容，包含：tasks, nextId, tags, snippets, nextSnippetId, settings

## 设计稿

`NookSwift/design/nook-panel-v1.html` — 最终确认的 HTML 设计稿（浅色+深色并排），浏览器打开可交互预览。所有交互逻辑（标签溢出、子任务展开、编辑弹窗、烟花特效、深浅切换）都在里面。

## 关键技术决策

1. **NSPanel 而非 NSWindow** — 需要 `canBecomeKey = true` 让 TextField 能获取焦点
2. **CGEvent tap** — 需要辅助功能权限，无权限时降级为 NSEvent 轮询
3. **Timer 驱动隐藏** — 鼠标离开面板 0.5s 后收起，不依赖鼠标移动事件
4. **Combine 同步 Pin 状态** — AppDelegate 用 `$isPinned.sink` 同步到 HotCornerManager
5. **JSON 持久化** — 不用 CoreData/SwiftData，保持与 Electron 版数据兼容
