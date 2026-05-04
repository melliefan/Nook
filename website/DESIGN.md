# Nook 官网 · 设计文档

> 给 Claude design / Cursor / 任意前端代码生成 AI 的**独立 brief**。  
> 收到这份文档不需要其他上下文,从头到尾按本文档生成代码即可。

---

## 1. 项目背景

**Nook** 是一个 macOS 原生待办面板 app(Swift + SwiftUI + AppKit)。

- 核心交互：鼠标撞到屏幕角落 → 面板从角落滑出 → 速记/勾选/进入热角再次撞角收起
- 定位：极简日常待办,不是项目管理工具
- 技术：原生 macOS 应用,5MB 体积,无服务器、无账号、本地 JSON 存储
- 已实现功能：任务/标签/截止/优先级、子任务、Apple Reminders 同步、CLI 工具(`nooktodo`)、快捷粘贴片段
- 当前版本:v1.0.0

**作者**: melliefan · 某国内大模型公司解决方案架构师 · 业余独立开发者

---

## 2. 网站目标

这个网站要同时承载三件事：

1. **Nook 产品介绍 + 下载**(主要)
2. **作者个人名片 / 作品集**(次要,未来还会有更多 app)
3. **海外友好** — 英文优先,中文可切换

**KPI**:
- 访客 → 下载转化率：争取 10%+
- 首屏让人 5 秒内理解 Nook 是什么
- 移动端能正常浏览(虽然下载的是 Mac 软件)

---

## 3. 域名 & 路由结构

```
melliefan.com/              ← 个人首页(personal landing,作者介绍 + 当前作品)
melliefan.com/nook          ← Nook 产品页(本次重点)
melliefan.com/nook/changelog ← 版本日志(可选)
melliefan.com/<下个 app>     ← 未来 app(预留路由结构)
```

**本次只设计两个页面：**
- `/` 个人首页(简单,3-4 个 section)
- `/nook` Nook 产品页(主要工作量)

---

## 4. 信息架构(/nook 产品页)

按用户阅读路径排序:

### 4.1 Hero(首屏)

要素：
- 大标题(产品名 + 一句 tagline)
- 简短描述(1-2 句)
- 主 CTA：`Download for macOS`(深色实心按钮)
- 次 CTA：`View on GitHub`(幽灵态)
- **核心视觉**：一个 macOS 桌面截图,鼠标在屏幕左上角,Nook 面板正从角落滑出(可以是动图或视频自动循环)

### 4.2 Hot Corner Mechanic(独家机制说明)

要素：
- 大标题：`Designed around the corner`(EN) / `专为屏幕角落而设计`(CN)
- 一段说明 + 一张高清示意图(屏幕四角,标出热角触发位置)

### 4.3 Feature Grid(功能矩阵)

3×2 或 2×3 卡片网格,每张卡：
- 一行图标
- 一行标题
- 1-2 行说明

功能列表：
1. **Tags & Filters** / 标签筛选 - 多色彩标签,一键过滤
2. **Hot Corner Trigger** / 热角触发 - 鼠标撞角呼出,无需快捷键
3. **Apple Reminders Sync** / 提醒事项同步 - 跨设备 iCloud 同步
4. **CLI Tool** / 终端命令行 - `nooktodo` 命令快速记录
5. **Snippets** / 快捷粘贴 - 常用文本一键复制
6. **Native & Light** / 原生轻量 - 5MB 安装包,无后台进程

### 4.4 Screenshots(视觉展示)

要素：
- 标题：`See it in action` / `亲自看看`
- 横向滚动或网格,4-6 张高清截图(浅色 + 深色)
- 截图素材：可让作者后期补,先用占位符 `[screenshot-light-main.png]` 等

### 4.5 Download(下载区)

要素：
- 大标题：`Get Nook`
- 系统要求：`macOS 14+ · Apple Silicon & Intel · 5MB`
- 下载按钮：`Download Nook v1.0.0 (.dmg)`
- 副信息：
  - "First time? Right-click → Open if macOS asks." (ad-hoc 阶段)
  - 之后改成："Notarized by Apple · safe to open."(Developer ID 阶段)
- 校验信息(SHA-256)

### 4.6 About / Author(作者简介)

要素：
- 头像 + 名字 + 一句 bio
- 链接：GitHub / X / Email
- "Made with care" 之类的暖色 footer(不写具体城市)

### 4.7 Footer

- 版权
- Changelog 链接
- Privacy(纯本地存储,无上报)
- Email / Source code

---

## 5. 信息架构(/ 个人首页)

更简单,2-3 个 section:

### 5.1 Hero

- 名字 + 一句话定位:`melliefan · Solutions Architect at a Chinese AI lab · Building tools on the side`
- 头像 / illustration

### 5.2 Currently Building(当前作品)

- 一张大卡:Nook(链接到 /nook)
- 占位:`More coming soon...`

### 5.3 Contact

- Email / GitHub / X

---

## 6. 视觉设计 Token

**严格对齐 Nook macOS app 的设计系统**(NookTheme.swift):

```css
/* Light theme */
--bg:        #FCFCFD;
--bg-alt:    #F1F1F4;
--text-1:    #1E1E2A;  /* 主文字 */
--text-2:    #5C5C6E;  /* 次文字 */
--text-3:    #8A8A96;  /* 弱文字 */
--text-4:    #BBBBC2;  /* placeholder */
--line:      #DDDDE2;
--accent:    #3A3A48;  /* 黑灰主色 — 按钮/强调 */
--accent-fg: #F7F7FA;  /* 主色上的文字 */

/* Dark theme(可选,首版可只做浅色) */
--bg:        #1A1A26;
--text-1:    #E5E5EA;
--accent:    #E5E5EA;
--accent-fg: #1A1A26;

/* Page background(网站本身,跟 app 略不同) */
--page-bg:   #DBDBDF;  /* 浅灰画布 */
```

**字体栈**：
```css
font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display",
             "PingFang SC", "Helvetica Neue", sans-serif;
font-family-mono: "SF Mono", "Menlo", monospace;
```

**字号 scale**(macOS 风格):
```
hero-display:  56-72px / weight 800 / letter-spacing -1.5px
h1:            36px / 700 / -0.6px
h2:            22px / 700 / -0.4px
h3:            16px / 600
body:          15px / 400 / line-height 1.65
small:         12px / 400
```

**圆角 / 阴影**:
- 卡片圆角:`14px`(跟 NSPanel 一致)
- 按钮圆角:`8px`
- Hero 截图圆角:`14px`
- 阴影:`0 12px 40px rgba(30,30,42,0.08), 0 0 0 1px rgba(30,30,42,0.04)`

**间距**:
- Section 之间:`80px`(desktop)、`48px`(mobile)
- 容器最大宽:`1100px`,内边距 `24px`

---

## 7. 风格基调(避免 AI slop!)

### ✅ 要做的

- **克制、温暖**:跟 Nook app 一脉相承,产品介绍像朋友推荐而不是营销
- **真实素材**:用真实截图,不要随便生成假 UI
- **大量留白**:Apple 风格的呼吸感
- **黑灰主色**:整站不要花哨配色,主色只有 `#3A3A48` 一个
- **语言克制**:每个 section 文字 ≤ 2 行说明,不堆砌形容词

### ❌ 严禁(AI 默认会犯的错)

- 紫色渐变背景(AI 生成网页的标志特征,看上去 generic 廉价)
- "10x productivity / supercharge / unleash" 这种 SaaS 套话
- 卡片左侧加彩色边框装饰
- 在文字旁边乱塞 emoji
- "Trusted by 10,000+ users" 这类编造的社会证明
- Inter 字体(用 SF Pro 或 system-ui)
- 浮夸的滚动动画(细微淡入即可,不要视差)
- 弹窗/cookie 横幅(本站无 tracking,不需要)

---

## 8. 文案(逐 section 草稿)

### 8.1 Hero(英文版)

```
Headline: A todo list that lives in the corner of your screen.
Sub:      Nook stays out of your way until you need it. Slam your
          mouse into a screen corner — your tasks slide in. Done
          with them? Push them back.

CTA-primary:   Download for macOS
CTA-secondary: View on GitHub
```

### 8.2 Hero(中文版)

```
标题:    一个住在屏幕角落的待办本
副标:    平时它不打扰你。鼠标撞向屏幕一角,任务便从角落滑出。
        记完事情,把它推回去。

CTA-主:  下载 macOS 版
CTA-次:  GitHub
```

### 8.3 Hot Corner Section

```
EN: Designed around the corner.
    Most apps live in your dock or menu bar. Nook lives in the
    corner of your screen — invisible until you push your mouse
    there. No keyboard shortcut to remember. No app to launch.
    Just a corner.

CN: 专为屏幕角落而设计。
    多数 app 在 Dock 或菜单栏占位置。Nook 住在屏幕的角落 ——
    平时看不见,鼠标撞到角落它就出现。不用记快捷键,不用启动,
    只需要一个角落。
```

### 8.4 Feature Grid 文案

| Feature | EN title + desc | CN title + desc |
|---|---|---|
| Tags | **Color-coded tags.** Filter by project, person, or context with a click. | **彩色标签.** 一键按项目、人、场景过滤。 |
| Hot corner | **Hot corner trigger.** No shortcut to memorize. Just push the mouse where you need it. | **热角触发.** 不用记快捷键,鼠标推过去就行。 |
| Reminders sync | **Apple Reminders sync.** Tasks with due dates appear on your iPhone via iCloud. | **Apple 提醒事项同步.** 带日期的任务通过 iCloud 自动出现在 iPhone。 |
| CLI | **Command-line companion.** `nooktodo "ship the thing"` from any terminal. | **命令行工具.** 终端里 `nooktodo "ship the thing"` 直接记录。 |
| Snippets | **Snippet shortcuts.** Stash text you copy often, paste with ⌥1/2/3. | **快捷粘贴.** 常用文本存一次,⌥1/2/3 直接粘。 |
| Native | **Native & light.** 5 MB. No background daemon. No account. | **原生轻量.** 5MB 安装包,无后台,无账号。 |

### 8.5 Download Section

```
EN:
  Get Nook
  macOS 14 (Sonoma) or later · Apple Silicon & Intel · 5 MB

  [Download Nook v1.0.0 (.dmg)]

  First time opening?  macOS may ask you to verify the developer.
  Right-click the app → Open → Open. (One-time per machine.)

CN:
  下载 Nook
  macOS 14 (Sonoma) 或更高版本 · Apple Silicon & Intel · 5 MB

  [下载 Nook v1.0.0 (.dmg)]

  首次打开?macOS 可能会提示验证开发者。
  右键点击 app → 打开 → 打开 (每台机子做一次即可)。
```

> 公证完成后改成:`Notarized by Apple · double-click to open / 经 Apple 公证 · 双击即可打开`

### 8.6 About

```
EN: Built by melliefan, a Solutions Architect at a Chinese LLM
    company. Nook is the first thing I've shipped on the side —
    I wanted a todo app that stays out of my way except when I
    need it. Hope it helps you too.

CN: melliefan 做的。我是某国内大模型公司的解决方案架构师,
    Nook 是我业余做的第一个产品 —— 想要一个平时不打扰、
    需要时一秒到位的待办本。希望对你也有用。
```

---

## 9. 交互细节

- **滚动**:section 进入视口时淡入(opacity 0→1, 300ms ease)。**不要做视差**
- **Hero 视觉**:静态截图 + 一个标志性 GIF 或 mp4(自动循环、静音、playsinline、loop) — 显示鼠标撞角 → 面板滑出
- **下载按钮**:hover 时背景从 `#3A3A48` → `#2A2A38`(略深),不要 transform
- **导航**:顶部固定 header,内容区滚动时 header 加 backdrop-blur
- **暗色模式切换**(可选,可推迟):右上角小开关,使用 `prefers-color-scheme` 默认跟随系统

---

## 10. 技术栈推荐

**强推荐:静态站,零后端**

| 组件 | 推荐选择 | 备注 |
|---|---|---|
| 框架 | **Astro** 或纯 HTML/CSS | Astro 适合多页 + i18n;纯 HTML 适合极简 |
| 样式 | **原生 CSS** 或 Tailwind | 原生 CSS 更轻量,本设计系统简单不需要 Tailwind |
| 部署 | **Cloudflare Pages** 或 Vercel | 都免费,Cloudflare 中国访问稍快 |
| 域名 DNS | Cloudflare Registrar | 跟 Pages 同账号,DNS 自动 |
| i18n | URL 前缀(`/en/`, `/zh/`) | 默认 `/zh/`,通过浏览器语言或手动切换 |
| 动图 | 一个 ~500KB 的 mp4 + autoplay loop muted playsinline | 比 GIF 小 10 倍 |

**不要用:**
- React / Next.js / Vue 等 SPA(过重,SEO 差)
- WordPress
- 任何需要数据库的方案

---

## 11. 性能 + SEO 基线

- **Lighthouse 分数全部 ≥ 95**(Performance / Accessibility / Best Practices / SEO)
- 图片 lazy-load,WebP 格式
- 字体只用 system-ui(不加载外部 web font)
- meta tags 齐全:`description`, `og:image`, `og:title`, `twitter:card`
- 一份合理的 sitemap.xml + robots.txt
- 结构化数据(JSON-LD)标识 SoftwareApplication

---

## 12. 资源占位符清单

设计/开发时这些素材先用占位符,作者后续补:

| 占位 | 说明 | 谁补 |
|---|---|---|
| `hero-screenshot.png` | 桌面 + Nook 面板从角落滑出 | 作者用真机录制 |
| `hero-demo.mp4` | 鼠标撞角触发面板的循环动图 | 作者用 macOS 录屏 + ffmpeg 转 mp4 |
| `feature-tags.png`-`feature-native.png` | 6 张 feature 卡片配图 | 作者从 app 截图剪裁 |
| `screenshot-light-1.png`-`-4.png` | 浅色多场景 | 作者 |
| `screenshot-dark-1.png`-`-4.png` | 深色多场景 | 作者 |
| `avatar.jpg` | 作者头像(已有) | 复用 logo 风格 |
| `og-cover.png` | 1200×630 social 卡片 | 作者后期 |

---

## 13. 验收标准

代码生成完成后,以下都通过才算 done:

- [ ] 单页能在 Chrome / Safari / 移动端正常显示
- [ ] 所有图片占位符明确标出,不报 404
- [ ] 浅色模式视觉一致(深色可选)
- [ ] Hero 5 秒内能让人理解 Nook 是什么
- [ ] 文案中文 + 英文双版各一份(URL 前缀切换)
- [ ] 下载按钮指向真实 DMG 文件
- [ ] 没有出现禁用元素(紫色渐变 / SaaS 套话 / Inter / 假数据)
- [ ] Lighthouse Performance ≥ 95
- [ ] 总 JS 体积 < 50KB(去掉视频)
- [ ] 合理的 meta tags + favicon + og 图片占位

---

## 14. 交付物

预期 claude design 输出:

```
website/
├── index.html              # 个人首页 / (中文默认)
├── en/index.html           # 英文版 /en/
├── nook/index.html         # /nook 中文
├── en/nook/index.html      # /en/nook 英文
├── assets/
│   ├── style.css
│   ├── nook-demo.mp4       # 占位
│   └── images/             # 占位图片
├── robots.txt
├── sitemap.xml
└── README.md               # 部署说明
```

或者用 Astro:

```
website/
├── astro.config.mjs
├── src/
│   ├── layouts/Base.astro
│   ├── pages/
│   │   ├── index.astro
│   │   ├── nook.astro
│   │   ├── en/index.astro
│   │   └── en/nook.astro
│   └── styles/
└── public/
    └── (静态资源)
```

---

## 15. 风格参考

如果 claude design 需要视觉参照,推荐这几个站点的风格:

- https://things.app/ — Cultured Code 的 Things 3,克制温暖
- https://reederapp.com/ — RSS 阅读器,极简
- https://raycast.com/ — 注意是 Raycast 的"产品介绍"部分,不是营销首页
- https://linear.app/ — 黑白克制,但稍微太"硬"
- 不要参照:典型 SaaS 落地页(Vercel / Stripe 之外的多数 YC 创业公司主页)

**目标气质**: Things 的温暖 + Linear 的克制,中间偏 Things 一些。

---

**END.** 把整个文档丢给 claude design / Cursor / 任意代码生成工具,从零开始生成。生成完后回到本仓库,作者补真实素材替换占位符即可。
