# Nook 官网 · 素材制作 Brief

> 配合 `website/DESIGN.md` 用。下面是把官网占位符全部替换成真材料的执行清单。
> 顺序建议:先录视频/截屏(技术活),再生 AI 配图(创作活),最后整合到网站。

---

## 0. 资产清单(全部要交付的 6 个文件)

| 文件 | 类型 | 尺寸 | 来源 |
|---|---|---|---|
| `hero-demo.mp4` | 循环视频 | 1200×750 · ≤1MB | 录屏 |
| `screenshot-light-1.png` | 截图 | 720×1400 @2x | 真机截图 |
| `screenshot-light-2.png` | 截图 | 720×1400 @2x | 真机截图 |
| `screenshot-dark-1.png` | 截图 | 720×1400 @2x | 真机截图 |
| `screenshot-dark-2.png` | 截图 | 720×1400 @2x | 真机截图 |
| `nook-cover.png` | 装饰图 | 1200×800 | AI 生成 |

可选额外(README + 社交分享):
| 文件 | 用途 |
|---|---|
| `og-image.png` (1200×630) | 社交分享卡片(Twitter/X、Facebook、微信) |
| `readme-hero.png` (1280×640) | GitHub README 顶部大图 |

---

## 1. hero-demo.mp4 — 核心动效录屏

### 1.1 内容设计(分镜)

**总时长 ≤ 6 秒**, 必须 loop 顺滑(首尾帧能接上)。

```
0.0s ─ 干净桌面(Safari 在浏览,Finder 在背景),光标在屏幕中央
1.0s ─ 光标向左上角移动
2.0s ─ 光标到达左上角,Nook 面板从角落滑出(原生动画 0.3s)
2.5s ─ 面板完全展开,显示 5-7 个任务(脱敏样本)
3.5s ─ 光标移开屏幕角落
4.0s ─ Nook 面板自动收回(0.5s 滑动)
5.0s ─ 回到干净桌面状态(== 0.0s 帧,完成 loop)
6.0s ─ 切片结束
```

### 1.2 录制工具(三选一)

| 工具 | 价格 | 推荐度 | 备注 |
|---|---|---|---|
| **Kap** (https://getkap.co) | 免费开源 | ⭐⭐⭐ | macOS 原生,自带 mp4/gif 导出,支持 60fps |
| **CleanShot X** | $29 | ⭐⭐⭐ | 最专业,鼠标点击高亮、键盘按键提示 |
| **QuickTime Player** | 已自带 | ⭐⭐ | 应急可用,但只能录 .mov,要 ffmpeg 转 mp4 |

强烈推荐 **Kap**:`brew install --cask kap`

### 1.3 录制前准备(临时打扫,文件本体不动)

**这些命令只改"是否显示",文件 100% 安全。录完一条对应命令复原。**

```bash
# 1. 隐藏桌面所有图标(文件还在,只是不画出来)
defaults write com.apple.finder CreateDesktop false && killall Finder
# 复原: defaults write com.apple.finder CreateDesktop true && killall Finder

# 2. Dock 自动隐藏
defaults write com.apple.dock autohide -bool true && killall Dock
# 复原: defaults write com.apple.dock autohide -bool false && killall Dock

# 3. 菜单栏自动隐藏(可选,菜单栏太花时用)
defaults write NSGlobalDomain _HIHideMenuBar -bool true && killall SystemUIServer
# 复原: defaults write NSGlobalDomain _HIHideMenuBar -bool false && killall SystemUIServer

# 4. 开"勿扰"(避免通知弹窗炸录屏)
# 控制中心 → 勿扰 → 开 (手动)

# 5. 关闭 Bartender / iStat Menus / 第三方 menubar 工具
# 一般退出对应 app 即可

# 6. 鼠标高亮(让光标在视频里显眼)
# Kap 设置里勾"显示鼠标"; CleanShot X 自带 "Highlight Cursor"

# 7. 屏幕分辨率
# 系统设置 → 显示器 → 选 1920×1200 或类似(避免 5K 录出来太大压缩慢)
```

### 1.4 录制 + 后处理

```bash
# 1. 用 Kap 录一段长一点的 (比如 10s),后期裁出最干净的 4-6s

# 2. 用 ffmpeg 压到 web 友好(假设录出来叫 raw.mp4):
ffmpeg -i raw.mp4 \
  -vf "scale=1200:750:flags=lanczos,fps=30" \
  -c:v libx264 -preset slow -crf 26 \
  -movflags +faststart \
  -an \
  hero-demo.mp4

# 3. 验证体积(应 < 1MB):
ls -lh hero-demo.mp4

# 4. 验证 loop:
# 用 QuickTime 打开,看是不是首尾顺滑接上;不顺就回去重剪。
```

> Tips: 想做高级版可以用 Final Cut/Davinci 加一个 0.5s 的 fade in/out,但视觉上不如直接 hard loop 自然。

---

## 2. 4 张静态截图

### 2.1 拍摄清单

| 文件 | 内容 | 模式 |
|---|---|---|
| `screenshot-light-1.png` | 主面板 + 5-7 个有混合状态的任务(完成/待办/逾期/优先级旗) | 浅色 |
| `screenshot-light-2.png` | 任务详情页(全字段:标题/描述/标签/子任务/截止日期) | 浅色 |
| `screenshot-dark-1.png` | 主面板 + 标签筛选条全展开 | 深色 |
| `screenshot-dark-2.png` | 设置 popover 展开(显示提醒事项同步开关) | 深色 |

### 2.2 拍摄步骤

```bash
# 准备脱敏样本任务(直接用 nooktodo 注入):
nooktodo "投标书最终稿"  -t 工作 -t 客户A -p high -d "+2d" -s "梳理招标要求" -s "完成预算测算"
nooktodo "技术方案 V3"   -t 工作 -p medium -d "+5d"
nooktodo "周报"          -t 工作 -d today
nooktodo "下周客户拜访"   -t 客户A -p low -d "-1d"  # 逾期
nooktodo "新工具调研"     -t 个人  -p medium
nooktodo "周一站会议程"   -t 工作  # 完成态
nooktodo done <id>  # 把上一条标完成

# 截图工具
# macOS 自带 ⌘⇧4 选区域截屏
# 或用 CleanShot X (能自动加圆角阴影)

# 关键:截图分辨率必须是 @2x retina (HiDPI)
# 系统设置 → 显示器 → 缩放选"看更多"(不要选"显示更大") 

# 截图后处理(可选):
# 给截图加圆角 + 投影框,让网站显示更精致:
# CleanShot X 自带,或用 https://shots.so (浏览器在线工具)
```

### 2.3 命名 + 输出

```
导出统一为 PNG @2x (retina),例如 720×1400 渲染像素 = 1440×2800 实际像素。
浏览器显示时 CSS 渲染为 720×1400 → 视觉清晰锐利。

文件名要严格匹配 website 里的 placeholder:
  screenshot-light-1.png
  screenshot-light-2.png
  screenshot-dark-1.png
  screenshot-dark-2.png
```

---

## 3. AI 生图提示词(给 ChatGPT / GPT-4o 用)

### 3.1 nook-cover.png — 个人首页 Nook 卡片封面

**用途:** 个人首页 `/` 上的 Nook 产品卡片背景配图,装饰性,不需要展示 UI。

**提示词(英文,GPT-4o image gen):**

```
A minimalist, atmospheric illustration of a cozy desk corner at golden hour:
a wooden desk surface partially visible at the bottom-left, a small framed
window in the upper-right showing soft morning light, a closed leather notebook
sitting at the corner intersection. The whole scene is rendered in a muted
palette: warm beige (#E8E4DC), graphite gray (#3A3A48), and pale cream
(#FCFCFD). Strong negative space in the upper-left two-thirds of the image.
Hand-drawn editorial illustration style, similar to The New Yorker covers.
NO text, NO logos, NO people. 16:10 aspect ratio.
```

**关键控制点:**
- "muted palette" + 具体 hex 色:防止 AI 出鲜艳色
- "NO text" 必须强调:GPT 默认会在图里写歪歪扭扭的英文
- "16:10 aspect ratio":对应 1200×750 输出

### 3.2 og-image.png — 社交分享卡片

**用途:** 朋友圈/Twitter/Facebook 分享链接时的预览图。1200×630。

**提示词:**

```
A clean editorial-style banner showing the abstract concept of a tidy work
corner. Centered: a small floating notebook icon (rounded square outline,
white fill, dark gray stroke #3A3A48), with the word "Nook" in elegant
serif typography below it (Georgia or Caslon style). Background: a very soft
gradient from warm cream (#FCFCFD) at top to pale gray (#F1F1F4) at bottom.
Tiny hairline corner brackets in graphite gray (#3A3A48) marking the four
corners of the canvas, hinting at "screen corners". 
Aspect ratio strictly 1.91:1 (1200×630). Minimal, no decorative elements,
no people, no characters, no shadows.
```

**Tips:** Twitter 卡片需要 `<meta name="twitter:card" content="summary_large_image">`,这块官网已经做了。

### 3.3 readme-hero.png — GitHub README 顶部大图(可选)

**用途:** GitHub repo 主页 README.md 顶部的大图,定调用。

**提示词(图生图模式 — 推荐):**

输入图:你的 hero-demo.mp4 第 2.5 秒的截图(面板完全展开那一帧)
Prompt:

```
Transform this screenshot into a polished product hero image suitable for a
GitHub README banner. Place the screenshot inside a stylized macOS desktop
mockup: a soft beige wooden desk surface (out of focus) at the bottom edge,
the Nook panel screenshot floating in the center-right with a subtle drop
shadow. Add empty negative space on the left for product name and tagline
(do NOT add the text yourself, just leave the space).
Color palette: warm cream background (#FCFCFD), graphite #3A3A48 accents.
Aspect ratio: 2:1 (1280×640). NO additional UI, NO people, NO text.
```

**纯文生图替代版**(如果不想图生图):

```
A polished product hero shot for a macOS todo app called "Nook":
A floating macOS panel window (rounded corners, soft glassy white surface,
visible shadow) on the right side of the canvas, showing a generic todo list
with checkboxes and minimal text bars (representational, no real text).
Background: blurred warm beige desk surface with soft morning light.
Empty negative space on the left side for branding text (do not add text).
Color palette: cream #FCFCFD, graphite #3A3A48, no other colors.
Aspect ratio 2:1. Editorial quality, NOT generic SaaS hero.
NO people, NO logos, NO text.
```

---

## 4. 图生图 — 把真截图加工成营销图

### 4.1 思路

GPT-4o / Midjourney 都支持上传参考图 + prompt 改风格。**真截图 + AI 包装** = 既准确又有美感。

适合做的:
- 把单张主面板截图放进"漂浮的 macOS window 在木桌上"的语境
- 把 4 张截图拼成一张 lifestyle 图(配音"用 Nook 的一天")
- 把 hero 截图变成水彩画/线稿等替代视觉版本(用作博客/社媒副图)

### 4.2 通用图生图 prompt 模板

```
[上传你的 Nook 截图]

Use this app screenshot as the central visual element. Place it inside a 
realistic macOS desktop mockup, floating in the [position] of the canvas, 
with a soft drop shadow. Surrounding context: [scene description].
Color grading: warm and neutral, matching the screenshot's design system 
(cream backgrounds, graphite accents, no saturated colors).
Do not modify the screenshot's UI content, only frame it.
Aspect ratio: [16:9 / 1:1 / 1.91:1].
NO additional text or graphics on top of the screenshot.
```

替换变量:
- `[position]`: center / right-third / floating top-right
- `[scene description]`: 比如 "a quiet home office at dawn, MacBook on a desk", "a cozy cafe table with a half-empty coffee cup", "minimalist workspace with a single succulent plant"

### 4.3 4 个具体图生图任务

#### 任务 A — Lifestyle 图: Nook on the desk

```
[上传 screenshot-light-1.png]

Place this app screenshot floating prominently in the upper-right of a 
photorealistic scene: a minimalist home office with a MacBook Pro sitting 
on a light oak desk, soft morning light streaming from a window on the left,
a small ceramic mug of black coffee, and a fern in a terracotta pot in the
distance. The screenshot should appear as if it's the actual content on the
MacBook screen, with subtle screen reflection. Cream and graphite color 
palette throughout. 16:9 aspect ratio. No people in frame.
```

#### 任务 B — 社媒动图分镜(单帧版,可后期串成 GIF)

```
[上传 hero-demo.mp4 截图]

Stylize this animation frame as a clean editorial illustration. Reduce the 
desktop wallpaper to a flat solid pale-cream color (#FCFCFD). Keep the Nook 
panel as a sharp recognizable element. Add a subtle red dot and dotted line 
showing the mouse path from screen center to the corner where the panel 
emerges. Caption-ready: leave 20% empty space at the bottom for text overlay
(do NOT add the text yourself). 1:1 square aspect ratio for Instagram.
```

#### 任务 C — 黑白线稿版(博客插图用)

```
[上传 screenshot-light-1.png]

Convert this UI screenshot into a clean black-and-white line illustration 
in the style of a technical product diagram or a Stripe-style illustration. 
Use only fine black lines on a white background. Keep all UI elements 
recognizable but reduced to outlines. Add subtle dotted callouts pointing to 
3 features: the hot corner indicator (top-left), the tag filter bar, and 
the snippets section. Do NOT add label text — just numbered circles (1, 2, 3).
Aspect ratio matches the original screenshot.
```

#### 任务 D — Dark mode 海报

```
[上传 screenshot-dark-1.png]

Place this dark-mode screenshot in the center of a dramatic black canvas 
(#0A0A12). Add a soft radial spotlight glow behind the panel (very subtle, 
warm white #FFF8E8, ~5% intensity, not gradient-rainbow). The panel should 
appear to float with a deep diffused shadow. The bottom-right of the canvas 
shows a faint geometric corner bracket in graphite #3A3A48 (4-5% opacity), 
echoing the "screen corner" concept. 16:9 aspect ratio. Cinematic, not loud.
```

---

## 5. README 配图(GitHub 仓库主页)

GitHub README 应该有的视觉:

```markdown
# Nook

[hero image — 用第 3.3 节生成的 readme-hero.png 或第 4.3 任务 A 的 lifestyle 图]

A macOS todo list that lives in the corner of your screen.

[badges — 这部分文字,不需要图]

## How it works

[一张主面板截图,使用 screenshot-light-1.png]

或者一张 GIF 演示(从 hero-demo.mp4 转,见下)

## Features

[要么用 SVG 图标 + 文字,要么用截图网格]
```

### 把 mp4 转 GIF 给 GitHub README 用(GitHub 不支持 mp4 内嵌,只支持 GIF):

```bash
ffmpeg -i hero-demo.mp4 \
  -vf "fps=15,scale=720:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  -loop 0 \
  hero-demo.gif

# GIF 通常会大很多(~3-5MB)。GitHub 限制 25MB 单文件,够用。
# 如果太大,降帧到 12fps 或缩到 600px 宽。
```

---

## 6. 文件组织

最终交付的资产应该这样放:

```
website/
├── assets/
│   ├── images/
│   │   ├── hero-demo.mp4
│   │   ├── hero-demo.gif         # GitHub README 用(可选)
│   │   ├── screenshot-light-1.png
│   │   ├── screenshot-light-2.png
│   │   ├── screenshot-dark-1.png
│   │   ├── screenshot-dark-2.png
│   │   ├── nook-cover.png
│   │   ├── og-image.png
│   │   └── readme-hero.png
│   ├── style.css
│   ├── main.js
│   └── favicon.svg
└── ... (其他 html 文件)
```

---

## 7. 执行顺序建议

```
W1 D1 (今天/明天):
  □ 准备好 5-7 条脱敏样本任务(用 nooktodo)
  □ 截 4 张静态截图(浅色 2 张 + 深色 2 张)
  □ 录制 hero-demo.mp4(花点时间多录几条选最好的)

W1 D2:
  □ 用 GPT-4o/ChatGPT 生 nook-cover.png
  □ 用 GPT-4o/ChatGPT 生 og-image.png
  □ (可选)生 readme-hero.png 或图生图 lifestyle 图

W1 D3:
  □ 把所有素材塞到 website/assets/images/
  □ 把官网占位符替换成真路径
  □ 跑一次本地 server 验证
  □ 部署到 Cloudflare Pages
  □ 写 README.md
  □ 推到 GitHub
```

---

## 8. 验收标准

每张图/视频检查:

- [ ] 文件名严格匹配清单(网站不会自动找)
- [ ] 视频 ≤ 1MB,首尾能 loop
- [ ] 截图 @2x retina,文件 ≤ 500KB(用 https://squoosh.app 压缩)
- [ ] AI 图里没有出现 ❌ 错别字 / ❌ 假手指 / ❌ 紫色渐变
- [ ] 所有图里没有泄露真实雇主名 / 客户名 / 邮箱
- [ ] 配色符合 #FCFCFD 浅 / #1A1A26 深 / #3A3A48 主色 系统

---

**END.** 按章节执行,有问题随时问。需要我帮你具体改 prompt(比如 nook-cover 想换氛围)直接说。
