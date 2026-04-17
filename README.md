# Nook · 角落

> 把鼠标滑到屏幕左上角，一个属于你的小角落悄悄亮起 —— 所有待办都在这里。
>
> 作者 [melliefan](https://github.com/melliefan) · UI 风格参考滴答清单浅色模式。

![平台](https://img.shields.io/badge/平台-macOS-lightgrey) ![electron](https://img.shields.io/badge/electron-37-blue) ![协议](https://img.shields.io/badge/协议-MIT-green)

## 功能特性

- **热角唤起**：无需快捷键、无 Dock 图标。鼠标移到屏幕左上角即自动滑出，移开即收起
- **自动避让 Dock**：检测系统 Dock 位置（如左侧），面板自动从 Dock 右侧起步，不被遮挡
- **任务管理**：四级优先级（高/中/低/无）、拖拽排序、已完成折叠分组、详情页可写描述和子任务
- **标签系统**：输入 `#标签名` 自动解析；20 种预设颜色；顶部两行堆叠筛选条；按标签过滤
- **截止日期**：今天 / 明天 / 下周 / 自定义；过期任务日期红色警示
- **搜索排序**：支持标题、描述、标签全文搜索；按优先级 / 日期 / 标题 / 创建时间排序
- **快捷粘贴**：底部常用命令和密码一键复制；密码默认打码显示，可切换查看
- **丝滑过渡**：透明常驻窗口 + 纯 CSS 滑入，无任何窗口闪烁

## 技术栈

- **Electron 37** 主进程 + 渲染进程
- **原生 JS + CSS**，无框架、无构建步骤
- **JSON 文件持久化**，数据存在 `~/Library/Application Support/Nook/data/tasks.json`
- **图标**：[Solar Bold Icons](https://icon-sets.iconify.design/solar/)（通过 Iconify）
- **字体**：SF Pro Rounded（自动回退 PingFang SC）

## 项目结构

```
src/
├── main/
│   ├── main.js       # 主进程：窗口、热角轮询、IPC
│   └── store.js      # JSON 持久化 + 数据结构迁移
├── renderer/
│   ├── index.html    # 面板 DOM 结构
│   ├── styles.css    # 滴答浅色风格主题
│   ├── app.js        # 全部交互逻辑
│   ├── icons.js      # 图标注册表
│   └── icons/        # Solar Bold SVG 源文件
└── preload.js        # 主进程 / 渲染进程 IPC 桥
```

## 本地开发

```bash
npm install
npm start
```

## 打包 macOS DMG

```bash
npm run dist:mac              # 当前架构
npm run dist:mac-arm          # Apple Silicon（M 系列芯片）
npm run dist:mac-x64          # Intel
npm run dist:mac-universal    # 通用（两种都包）
```

产物输出到 `dist/`，双击 `.dmg` 拖入「应用程序」即可安装。

> 未做 Apple Developer 代码签名的构建会被 Gatekeeper 拦截。首次打开：右键 `Nook.app` → 打开 → 在弹窗里点「打开」按钮确认一次，之后双击即可。

## 操作指引

| 操作 | 方式 |
|---|---|
| 唤出面板 | 鼠标移到屏幕左上角（8×8 像素触发区） |
| 收起面板 | 鼠标移出面板右边约 20 像素 |
| 添加任务 | 点击「添加任务」或按 `⌘N` |
| 搜索 | 点击搜索图标或按 `⌘F` |
| 添加标签 | 在输入框里写 `#标签名 ` 空格结尾，或点工具栏标签按钮 |
| 查看 / 编辑任务 | 单击任务主体（滑入详情页） |
| 删除任务 | 右键 → 删除，或任务右侧垃圾桶图标 |
| 复制片段 | 点击片段整行即复制到剪贴板 |
| 返回列表 | `Esc` 或返回箭头 |

## 数据 & 隐私

所有数据只在本机 Electron `userData` 目录里保存一个 JSON 文件，不会上传任何地方。首次运行如发现旧版本数据（项目根目录的 `data/` 或 `corner-todo` userData），会自动迁移到新路径。

**快捷粘贴里的密码是明文存储**，适合放本地开发常用的命令片段（如 `ssh` 连接、Token 等），**请勿用来保存生产环境敏感凭据**。如需真正加密存储，建议用 macOS 钥匙串或专业密码管理器。

## 设计参考

UI 配色体系来自滴答清单 Web 浅色模式：

- 品牌主色 `#4772FA`
- 优先级四色体系 —— 红 / 橙 / 蓝 / 灰
- 圆形复选框、任务项 `4px` 圆角
- 系统字体栈优先使用 SF Pro Rounded / PingFang SC

## 致谢

- **图标**：[Solar Icon Set](https://github.com/480design/solar-icon-set) Bold 变体，通过 [Iconify JSON](https://github.com/iconify/icon-sets) 获取
- **设计灵感**：[滴答清单](https://dida365.com) 浅色模式

## 协议

MIT © melliefan
