# Nook · 出海商业化执行文档

> 版本 v1.0 · 2026-05-04 · 维护者:melliefan
> 文档定位:这是 working doc。决策、数字、计划会随实际执行迭代,改了直接更新。
> 关键决策已全部锁定,不再开放重审,见 §12 决策记录。

---

## 目录

- [0. 一页执行摘要](#0-一页执行摘要)
- [1. 战略定位](#1-战略定位)
- [2. 市场决策:为什么走出海](#2-市场决策为什么走出海)
- [3. 商业化模式](#3-商业化模式)
- [4. 定价](#4-定价)
- [5. GTM 渠道](#5-gtm-渠道)
- [6. 收款基建](#6-收款基建)
- [7. 税务结构](#7-税务结构)
- [8. 合规](#8-合规)
- [9. 售后](#9-售后)
- [10. 90 天执行计划](#10-90-天执行计划)
- [11. KPIs 与决策门](#11-kpis-与决策门)
- [12. 风险与预案](#12-风险与预案)
- [13. 财务预测](#13-财务预测)
- [14. 资源与推荐阅读](#14-资源与推荐阅读)
- [15. 决策记录](#15-决策记录)

---

## 0. 一页执行摘要

| 项 | 决定 |
|---|---|
| **产品** | Nook · macOS 待办面板,鼠标撞角呼出 |
| **市场** | 海外为主(欧美 + 日韩 + 全球英文)+ 国内小红书副线 |
| **定价** | $9 一次性买断(永久许可) |
| **收款** | Paddle (Merchant of Record) + Setapp 订阅分成 |
| **主体** | 现阶段个人 → 月入 ≥ $3K 后注册个体工商户 |
| **GTM** | Hacker News + Product Hunt + Reddit r/macapps + Setapp + 小红书 |
| **税务** | 海外 Paddle 已扣税,国内每年 3.31 自行申报 |
| **签名分发** | Apple Developer Program $99/年 + DMG 公证签名,不走 Mac App Store |
| **支持** | Email (`melliefan.mail@gmail.com`) + GitHub Issues |
| **首发时间** | Apple 证书拿到 1-2 周后(详见 §10) |
| **第一年目标** | $5K-30K 净收入 + 1000+ 付费用户 + 验证 indie 路径可走 |

**核心判断**:Mac 工具类海外 indie 是真实商业路径,关键不是"能不能赚钱",是"能不能熬到产品被发现"。前 90 天的 GTM 比代码本身更决定生死。

---

## 1. 战略定位

### 1.1 Nook 是什么

一个 macOS 原生待办面板。

- **核心交互**:鼠标撞屏幕角落 → 面板从角落滑出 → 速记/勾选/再次撞角收起
- **技术栈**:Swift + SwiftUI + AppKit (5MB 安装包)
- **本地优先**:JSON 文件存在 `~/Library/Application Support/Nook/`,无服务器、无账号、无上传
- **已实现**:任务/标签/截止日期/优先级/子任务/Apple Reminders 同步/CLI(`nooktodo`)/快捷粘贴

### 1.2 目标用户(精准)

✅ **核心人群:**
- macOS 工作的开发者、设计师、产品经理
- 想要"轻量本地工具"代替 Things/TickTick 等"全功能但臃肿"的待办 app
- 喜欢键盘+鼠标流的极客类用户
- 隐私敏感(讨厌账号 + 云同步)的用户

❌ **不是给:**
- 团队协作场景(没有同步)
- 项目管理场景(不是 Notion/Linear 替代)
- 重度 GTD 用户(没有项目/上下文/sequence 等高级功能)

### 1.3 一句话价值主张

**EN**: A todo list that lives in the corner of your screen.

**CN**: 一个住在屏幕角落的待办本。

### 1.4 跟竞品的差异

| 竞品 | 价位 | 区别 |
|---|---|---|
| **Things 3** | $49.99 一次性 | 重型 GTD,Nook 极简 |
| **TickTick** | $35.99/年订阅 | 跨平台账号,Nook 本地 macOS 专属 |
| **Reminders.app** | 免费 | Apple 自带但不专注桌面 panel,Nook 集成 Reminders |
| **Stickies (内置)** | 免费 | 视觉单一,Nook 有现代 UI + tag/优先级 |
| **OmniFocus** | $99.99 | 专业 GTD 重型,Nook 轻型 |

**Nook 的差异化护城河**:
1. **Hot corner 触发** — 没有竞品做这个交互
2. **超轻量** — 5MB,无后台,无账号
3. **价格** — $9 vs Things $50

---

## 2. 市场决策:为什么走出海

### 2.1 三个决定性事实

**事实 1:国内 macOS DMG 几乎无人付费**(参考 [19118] 哥飞 / 刘小排访谈)

```
国内不付费根因:
- 跨境收款门槛高(支付宝/微信缺少正经主体)
- 用户付费习惯弱(尤其桌面软件)
- 盗版生态(xclient.info 等站直接发破解版)
- 阿里腾讯字节免费工具铺满需求
```

**事实 2:海外 Mac 用户付费意愿强**(参考 Setapp 2024 数据 + Steve Hanov 案例 [37795])

```
海外 indie macOS 真实案例:
- Steve Hanov: 6 产品 $60K+/月 营收
- Paw / Bear / Reeder / Things: 全部走 $30-100 一次性买断模式
- Setapp 拥有 100,000+ 月度订阅用户(美元市场)
- HN/PH 评论一致:"$10 one-time 比 $2/月好卖"
```

**事实 3:Paddle / Lemon Squeezy 让中国 indie 出海前所未有简单**(经验/技术域知识)

```
跨境收款门槛已被 MoR (Merchant of Record) 模式拆掉:
- Paddle 支持中国大陆个人银行卡直接收款
- Paddle 自动处理 200+ 国家的 VAT/GST/Sales Tax
- 你只面对 1 个对手方(Paddle),不面对全球税务局
- 5% + $0.5 手续费(对独立开发者很合理)
```

### 2.2 决策

> **ALL IN 海外** + 国内小红书做副线低成本流量。
> 不投资源做国内合规、ICP 备案、微信支付商户。
> 国内朋友想买直接走 Paddle 海外链接(支持微信支付)。

---

## 3. 商业化模式

### 3.1 主模式:**一次性买断 $9**

- DMG 直接下载,Paddle 收款,license 长期有效
- 永久使用,终身免费更新到 v1.x 版本
- v2 大版本可选 +$5 升级(可能 3-5 年后)

**为什么不订阅:**
- HN / PH / Reddit 用户对 Mac 工具订阅极度反感
- Steve Hanov 的 boringBar 案例评论区一致 "$10 one-time" > "$2/month"
- Nook 是工具类,没有持续服务价值不该收持续费用
- 退款率低,无 churn 计算压力

### 3.2 副模式:**Setapp 订阅分成**

- 申请加入 [Setapp](https://setapp.com/developers)(macOS 订阅市集)
- Setapp 用户付 $9.99/月解锁 240+ Mac apps,Nook 是其中之一
- 按月活分成,通常每个 active user $0.30-$0.80
- **不冲突:** 用户可选 Setapp(订阅) 或 你的网站(买断)

### 3.3 未来扩展:**AI Pro 升级 +$5**

(v1.5 / v2 阶段考虑,不是 launch 必做)

- 增加 AI 整理任务、智能时间建议、自然语言录入等功能
- 一次性 +$5 升级 (累计 $14 永久持有)
- 不动主版本免费策略(避免"剥夺感")

---

## 4. 定价

### 4.1 主线

```
                                Nook v1.0
                                ───────────
直接购买(官网 / Paddle):      $9 一次性 永久
Setapp 用户:                  $0(包含在 $9.99/月 订阅里)

折扣:
- 学生 50% off ($4.5,凭 .edu 邮箱)
- 早鸟 launch 周 50% off ($4.5)
- 中国大陆用户(IP 检测) 30% off ($6.3) — 可选
```

### 4.2 为什么 $9 而不是其他价位

| 价位 | 利弊 |
|---|---|
| $4.99 | 太便宜,显得不严肃,影响品牌 |
| **$9** ⭐ | 甜蜜点,低于 PSY 阈值($10),冲动购买 |
| $14.99 | 工具类有点贵,影响转化 |
| $29 | Things 3 是 $49,对标后嫌贵不够 |

**心理学**: $9 跟 "less than 10 USD" 相比,转化率不一样。

### 4.3 退款政策

- **14 天无理由全额退款**(Paddle 默认/最低标准)
- 30 天内出现"无法启动 / 数据损坏" 等严重 bug → 全额退
- 退款率 < 5% 是健康基线,> 10% 是产品有问题

---

## 5. GTM 渠道

### 5.1 优先级矩阵

```
                  Tier 1 (必做)         Tier 2 (并行)        Tier 3 (长期)
                  ────────────────       ──────────────      ────────────────
海外 主渠道       Hacker News             Twitter/X           SEO 自然流量
                  Product Hunt           dev.to / Medium     指南站收录
                  r/macapps              个人博客             GitHub README
                  Setapp                                     
                  
国内 副渠道       (无)                   小红书              微信公众号
                                        豆瓣小组
```

### 5.2 Tier 1 详细打法

#### 🔥 Hacker News (Show HN)

**最重要的单点。** Mac 工具类发布的"流量赛车场"。

```
准备清单:
- 800-1200 字技术帖(讲实现细节,不是营销)
- 一张 hero gif/mp4 (鼠标撞角 → 面板滑出)
- 5-7 张静态截图(浅色/深色/详情)
- 完整的 GitHub repo (源代码可见加分)
- 已签名公证的 DMG 链接
- 个人 HN 账号(注册半年以上 + karma 100+ 加权)

发帖时机:
- 美东时间 周二/周三 早 7-9am
- 标题:"Show HN: Nook – A macOS hot-corner todo list"
- 不要 emoji,不要"我做了..."

发帖后:
- 一直在评论区回 (前 3 小时是 critical 期)
- 不要删差评,认真回复
- 不要刷票/拉群投票(会被 shadowban)
```

#### 🚀 Product Hunt

```
准备清单:
- 5 张产品图(1270×760 主图 + 4 张次)
- gallery video (60s mp4 demo)
- "First comment" 草稿(讲故事,自我介绍)
- 5-10 个 hunter 朋友提前打招呼

发帖时机:
- 太平洋时间 周二/周三 12:01am
- 提前 2 周开始 building "upcoming" 关注

目标:
- 当天 top 5 (前期获得 200-500 visits)
- 当周 top 20 (slack/discord 积累)
- 月度 top 100 (可写到产品页 "Featured on PH")
```

#### 💬 Reddit r/macapps

```
准备清单:
- 700 字简介(讲故事不卖货)
- 3-5 张截图直接贴
- "What problem it solves for you" 切入点

发帖技巧:
- 周末晚上美东时间(9-11pm Sat/Sun)
- 不发 link 直接贴 markdown,重点放在 self-text
- subreddit rules 先看,新成员有限制
- 同步发 r/macOSBeta, r/iPad (跨 sub)
```

#### 📦 Setapp 申请

```
- 提交时间: launch 后 1-2 周(有数据更好通过)
- 审核周期: 3-6 周
- 通过后: 多个流量入口,被动收入开始

申请链接: https://setapp.com/devs
```

### 5.3 Tier 2 并行打法

**Twitter/X (Build in Public):**
- 每周 2-3 条 update + 截图
- 关注 @levelsio / @dhh / @marclou / @sahilbloom 等并互动
- launch 当天发 thread 总结

**dev.to / Medium / 个人博客:**
- 写 3-5 篇技术文章
  - "How I built a hot-corner todo on macOS"
  - "Why I quit Electron for Swift mid-project"
  - "The economics of $9 indie macOS apps"
- 一篇文章可以多平台发(只改首段)

**小红书(国内副线):**
- 5-7 篇笔记,中文化,讲使用场景
- 直接放 melliefan.github.io/nook 链接
- 标签:#mac工具 #macOS #独立开发者 #效率工具
- 不投钱推流,纯免费有机增长

### 5.4 Tier 3 长线

**SEO 自然流量(参考 [218025] 哥飞《养网站如种果树》):**
- 数据点: 半年才到 28 天 7K 点击
- 上线 2-3 个月专注外链建设(指南站收录、博客 backlink)
- 不要继续无尽迭代代码 — 那是逃避做不擅长的事
- 工具站抗 AI 替代(Google 算法偏向工具站,降权 Listicle)

**指南站收录清单(免费一次性提交):**
- [Toolify](https://www.toolify.ai)
- [TAAFT](https://theresanaiforthat.com)
- [PH alternatives](https://www.alternativeto.net)
- [Mac AI](https://macai.com)

---

## 6. 收款基建

### 6.1 Paddle (主推荐)

**类型**: Merchant of Record (法律意义上的卖家)

**优势:**
- 中国大陆个人银行卡直接收款(招行/中行/工行)
- 全球 200+ 国家自动处理 VAT/GST/Sales Tax
- 自动开发票给买家(你不需要管)
- 7-30 天打款周期到你银行卡

**手续费:**
- 5% + $0.5 / 单
- $9 单 → 你实收 ~$8.05

**注册流程:**
1. https://paddle.com 注册账号
2. KYC: 上传身份证 / 护照 / 地址证明
3. 填 W-8BEN 表(免美国 30% 预扣税)
4. 绑定中国银行卡 + 选 USD/CNY 收款
5. 审核 1-3 天
6. 通过后接入 Paddle.js 或托管支付页

**集成方式 (推荐):**
- 网站直接放 Paddle 托管支付链接
- 用户点击 → 跳转 Paddle 收银台 → 完成支付 → 邮件发 license key
- 不需要后端,纯前端集成

### 6.2 Lemon Squeezy (备用)

- Paddle 替代品(2024 被 Stripe 收购,背景更稳)
- 操作类似 Paddle
- 5% + $0.5 / 单
- 中国卖家友好度更高(后台 UI/UX 更现代)
- 备选预案: Paddle 注册不通过时切换

### 6.3 Setapp (副渠道)

- 不是直接收款,是分成模式
- Setapp 收用户 $9.99/月 → 按 active user 分成给你
- 实际数据: 每个 active user 每月 $0.30-$0.80(根据使用率)
- 假设 1000 active users / 月 → $300-800/月被动收入

### 6.4 不要碰

❌ **Stripe 直连**:你必须自己是 Merchant of Record,要在每个国家处理税务。复杂度 10×。
❌ **PayPal 直接收款**:中国账号易封,提现费用 4-6%
❌ **Gumroad**:10% 手续费太贵,还要自己处理税务

---

## 7. 税务结构

### 7.1 当前(Phase 1: 个人身份)

```
适用:月收 < $3K (年 < $36K)
税种:综合所得(劳务报酬部分,3-45% 累进)
申报:每年 3 月 31 日前,个人所得税 APP

优点: 0 注册成本,极简
缺点: 高收入累进税率高
```

### 7.2 月收 ≥ $3K 时(Phase 2: 个体工商户)

```
适用:月收 $3K-15K (年 $36K-180K)
注册:当地政务网,费用 ~¥200,1 天完成
经营范围:"软件开发,信息技术服务"
税种:经营所得(5-35% 累进)+ 增值税(小规模 1%)
申报:每月增值税,每年汇算清缴
银行:对公账户(招商/平安/工行 indie 友好套餐)

优点: 可扣除成本(域名/服务器/笔记本电脑),综合税率低
缺点: 需要简易记账,代记账 ¥200-300/月
```

### 7.3 月收 ≥ $20K 时(Phase 3: 园区核定征收)

```
适用:月收 ≥ $20K (年 ≥ $240K)
做法:把个体工商户注册到税收优惠园区(海南/前海/西部)
园区"核定征收"政策可能让综合税率 → 3-5%
找当地代记账打听政策

优点: 大幅降低税率
缺点: 异地办理麻烦,要找靠谱代记账
```

### 7.4 年收 ≥ $200K 时(Phase 4: 海外架构)

```
适用:年收 ≥ $200K
做法:在新加坡 / 香港 / 美国 LLC 注册公司持有产品
公司收 Paddle 款 → 给你出薪 / 分红

优点: 国际税务规划空间大
缺点: 年成本 $1-3K,需要专业税务咨询(¥10K+ 一次性)
```

### 7.5 W-8BEN 关键说明

- Paddle / Lemon Squeezy 注册时让你填这个表
- **作用**: 证明你是非美国税务居民,免除美国 30% 预扣税
- 不填 → 美国扣 30%,你净收 $9 × 0.95 × 0.7 = $5.99
- 填了 → 你净收 $9 × 0.95 = $8.55

### 7.6 误区警告

❌ "Paddle 已扣海外税,中国不用申报"  
✅ 错。**中国仍需自行申报**。Paddle 给你的款是境外服务收入,要在国内交个税/经营所得税。

❌ "用 Paddle 就万事大吉,不需要主体"  
✅ 错。短期个人身份可以,但长期(年 > $50K)必须有主体,否则税务有风险。

❌ "海外公司更省税"  
✅ 不一定。中国大陆居民全球收入要报中国税。海外公司只在年收入很高、有专业税务规划时才划算。

---

## 8. 合规

### 8.1 法律文件清单

| 文件 | 必须吗 | Nook 怎么处理 |
|---|---|---|
| **Privacy Policy** | ✅ 必须(GDPR/CCPA) | 1 页:本地存储,不收集,不上传任何数据 |
| **Terms of Service** | ✅ 必须 | 用 Paddle 模板 + 自定义 license 条款 |
| **Refund Policy** | ✅ 必须 | 14 天无理由 + 30 天 bug 退款 |
| **EULA (端用户许可)** | ⚪ 可选 | 嵌入到 ToS 里即可 |
| **Cookie Policy** | ⚪ 可选 | 网站不用 cookie,可省 |

### 8.2 GDPR 合规要点

- 用户数据完全本地(`~/Library/Application Support/Nook/`)
- 不上传服务器,不发送任何 telemetry
- Privacy Policy 明确说明这点
- 用户随时可删 → 直接卸载 app + rm 该文件夹

### 8.3 Apple 合规

- **Apple Developer Program** $99/年(已决定注册)
- **Developer ID Application 证书**:用于签名 DMG 分发
- **Notarization (公证)**:macOS 14+ 必须,绕开 Gatekeeper 警告
- **Hardened Runtime**:开启,公证要求
- **不走 Mac App Store**:Nook 的 hot corner 用 CGEvent.tapCreate,沙盒禁止

### 8.4 国内合规(选择性放弃)

❌ ICP 备案 — Nook 部署在 GitHub Pages,不需要
❌ 微信支付商户 — 走 Paddle 即可,微信支付通过 Paddle 接入
❌ 数据出境备案 — Nook 不收用户数据
❌ 网络安全等保 — Nook 不是网络服务

**结论**: 国内合规这块用 GitHub Pages + 海外 Paddle 完美绕开。

---

## 9. 售后

### 9.1 渠道矩阵

| 渠道 | 优先级 | 响应基线 |
|---|---|---|
| **Email** (`melliefan.mail@gmail.com`) | ⭐ 主力 | 24-48h |
| **GitHub Issues** | ⭐ 公开 | 24-72h |
| **Twitter/X DM** | 紧急通道 | 8-24h |
| **Discord** | ❌ 不做(低于 1K 用户没必要) | - |
| **微信群** | ❌ 不做(干扰大,无法 set boundary) | - |

### 9.2 期望管理

README 和官网明确写:

> "Nook is built and supported by one indie developer. Expect 1-2 day response on most issues. Critical bugs are addressed in 24h."

海外用户对 indie 极度宽容,主动设预期反而获得好感。

### 9.3 文档体系

```
website/docs/         (慢慢建)
  ├── getting-started.md
  ├── faq.md
  ├── troubleshooting.md
  └── changelog.md
```

第一版 launch 不需要这些,可以先用 README + GitHub Wiki 撑过去。

### 9.4 反馈循环

- 收集所有反馈 → 月度归档 → 决定 v1.1 优先级
- 高频问题 → 加入 FAQ → 减少重复回复
- bug → GitHub Issues 公开追踪 → 修复后 close 通知用户

---

## 10. 90 天执行计划

### Day 1-30 · Pre-Launch + Launch

**🟦 你做(用户行动):**

- [ ] 注册 Apple Developer Program ($99/年)
- [ ] 创建 Developer ID Application 证书
- [ ] 创建 App Store Connect API Key
- [ ] 注册 Paddle 账号 + KYC + 绑定银行卡
- [ ] 注册 Lemon Squeezy 账号(备用)
- [ ] 用 Screen Studio 剪 hero-demo.mp4
- [ ] 用 GPT-4o 跑 nook-cover.png + og-image.png
- [ ] 准备 HN Show HN 草稿(800 字)
- [ ] 准备 Product Hunt 素材(5 图 + 60s 视频)
- [ ] 准备 r/macapps 帖子草稿
- [ ] 写 3 篇博客草稿 (放到 launch 后陆续发)
- [ ] 注册 Twitter @melliefan_dev (如还没)

**🟩 我做(Claude 协助):**

- [ ] 完成 release 流水线脚本(`sign-and-notarize.sh`, `build-dmg.sh`, `notarize.sh`)
- [ ] 写 hardened runtime entitlements
- [ ] 升级 build.sh 支持开发者签名
- [ ] 写 Privacy Policy / Terms / Refund Policy 模板
- [ ] 在 melliefan.github.io 加 Privacy/Terms 页面
- [ ] 协助 Paddle 集成(支付链接 + license 邮件模板)
- [ ] 写 launch 帖子文案(HN/PH/Reddit 三版)
- [ ] 把 hero-demo.mp4 嵌入官网

**🎯 Day 30 KPI:**
- ✅ Apple 公证完成,DMG 双击直接打开
- ✅ Paddle 收款通道开通
- ✅ HN Show HN 发布(目标 100+ upvotes)
- ✅ Product Hunt 发布(目标 Day 1 #5+)
- ✅ Reddit 发布(目标 30+ upvotes)
- ✅ 售出第一批早鸟单(目标 30 单 = ~$240)

---

### Day 30-60 · Optimize

**目标**: 收集反馈,出 v1.1,把流量沉淀。

**任务:**

- [ ] 监控 HN/PH/Reddit 反馈,记录所有 bug + feature requests
- [ ] 决定 v1.1 优先级(修最痛 + 加最多人要的功能)
- [ ] 提交 Setapp 申请
- [ ] 写 launch retro 帖子("How my Show HN went, what I learned")
- [ ] dev.to / Medium 发 3 篇技术博客(每周 1 篇)
- [ ] Twitter/X 发 launch thread
- [ ] 小红书发 5-7 篇笔记(国内副线)
- [ ] 给提指南站(Toolify, TAAFT, PH alternatives 等 5+ 站)
- [ ] 监控 Google Search Console,查看 SEO 起步情况

**🎯 Day 60 KPI:**
- ✅ 累计 100+ 付费用户(~$900)
- ✅ Setapp 申请通过(预期 3-6 周审核)
- ✅ v1.1 发布(修关键 bug + 加 1-2 个 feature)
- ✅ Twitter 关注 100+(launch + 博客带流量)

---

### Day 60-90 · Validate + Pivot Decision

**目标**: 用前 60 天数据决定下一步。

**关键评估:**

```
评估表:
─────────────────────────────────────────────
                          Best     OK     Bad
累计销量:                 200+     100    < 50
HN/PH 发布反馈热度:       Frontpage  Top10  无
Setapp 通过情况:          通过      审核   拒
月活用户:                 300+     150    < 50
退款率:                   < 3%     5-10%  > 10%
```

**Day 90 决策树:**

```
如果 ≥ Best:
  → 继续 Nook v1.x 迭代
  → 启动 Nook v2 大版本规划(AI 增强 +$5)
  → 启动第二个 indie 产品(避免 single-product 风险)

如果 ≥ OK:
  → 继续 v1.x,但加快迭代节奏
  → 增强 SEO + 内容
  → 暂不启动第二产品

如果 ≤ Bad:
  → 反思:产品定位 / 定价 / 渠道哪里有问题
  → 转免费 + 降低预期(纯简历项目化)
  → 启动其他想法,Nook 维持现状
```

**任务:**

- [ ] 写 Day 90 复盘文章(私密 + 公开版)
- [ ] 启动 v1.2 计划
- [ ] 准备 v2 / 下一个产品的 brainstorm
- [ ] 重新评估营销渠道 ROI

---

## 11. KPIs 与决策门

### 11.1 北极星指标

**核心**: 月度净收入(USD)

```
v1.0 launch (Day 30):     $200-500
M1 (Day 60):              $500-1000
M3 (Day 90):              $1000-3000
M6:                       $2000-5000
M12:                      $5000-10000
```

**重要次级指标:**
- 月活用户(MAU)
- 转化率(visit → paid)
- 退款率
- HN/PH 流量贡献占比
- 自然 SEO 流量

### 11.2 决策门(每个里程碑必须问的问题)

**Day 30 决策门:**
- [ ] HN 发布发了吗?Top 10 进了吗?
- [ ] Paddle 通了吗?第一笔款收到了吗?
- [ ] Apple 签名公证一切顺利吗?

**Day 60 决策门:**
- [ ] Setapp 通过了吗?
- [ ] 累计销量超过 100 单了吗?
- [ ] 复购或推荐有发生吗?

**Day 90 决策门:**
- [ ] Nook 是不是值得继续投入?(根据 §10 的 Best/OK/Bad 表)
- [ ] 第二产品 idea 准备好了吗?
- [ ] 注册个体工商户的时机到了吗?($3K/月触发线)

---

## 12. 风险与预案

| 风险 | 概率 | 严重性 | 预案 |
|---|---|---|---|
| **Apple 公证失败** | 低 | 高 | 重提交,联系 Apple Support。最坏继续 ad-hoc 签名 + 用户右键打开 |
| **Paddle KYC 不过** | 中 | 中 | 切换 Lemon Squeezy 备用 |
| **HN Show HN flop** | 中 | 中 | 不依赖单点,Reddit + PH + Setapp 是 backup |
| **Setapp 审核不过** | 中 | 中 | 自己网站直销 + Reddit/HN 持续推 |
| **国内税务稽查** | 低 | 高 | 月收 ≥ $3K 立即注册个体工商户,合规化 |
| **抄袭/克隆出现** | 中 | 低 | 你的时间护城河 + brand 累积。继续做长尾 SEO |
| **macOS 系统更新破坏 hot corner** | 低 | 高 | 监控 dev preview,提前适配 |
| **原工作时间冲突** | 高 | 中 | 设定每周固定 indie 时间(周末 + 工作日晚) |
| **健康问题(熬夜)** | 中 | 高 | 守住"持续推软件"的"持续",不要 burnout 一次性梭哈 |

---

## 13. 财务预测

### 13.1 成本(年度)

| 项 | 金额(USD) |
|---|---|
| Apple Developer Program | $99 |
| 域名(暂时不买,github.io 免费) | $0 |
| Paddle 手续费 | 销售额的 5.5% |
| Setapp 平台分成 | 平台收入的 30% |
| ChatGPT Plus(生图/写文案用) | $240 |
| 工具(Kap/Screen Studio 等) | $0-150 |
| 代记账(月收 ≥$3K 起) | $300-500 |
| 杂项(域名注册商/SSL/工具等) | $50 |
| **年度总成本** | **$700-1100 + 销售额 5.5%** |

### 13.2 收入预测(乐观/基准/悲观)

| 时段 | 悲观 | 基准 | 乐观 |
|---|---|---|---|
| Q1 (M1-3) | $500 | $2,000 | $5,000 |
| Q2 (M4-6) | $1,500 | $5,000 | $12,000 |
| Q3 (M7-9) | $2,500 | $8,000 | $20,000 |
| Q4 (M10-12) | $4,000 | $12,000 | $30,000 |
| **Year 1 总** | **$8,500** | **$27,000** | **$67,000** |

### 13.3 净利预测(基准场景)

```
营收:               $27,000
减 Paddle 手续费:    -$1,485 (5.5%)
减 Setapp 分成:     -$1,500(估)
减 工具/服务费:      -$500
减 个体户税(~10%): -$2,400
─────────────────────────
净利:               ~$21,000 ≈ ¥150,000
```

**基准场景的对比**: ¥150K 是三线城市平均年薪水平。**对一份"业余项目"来说极有吸引力**。

### 13.4 break-even 分析

- 单单净 $8.55 (Paddle 5.5% 后)
- 年度成本 $700 base + 销售 5.5%
- 想 break-even: 销售 ≥ 100 单 / 年(目标极易达到)
- 想超过 Apple Developer 账号 + 一年成本: 销售 ≥ 130 单

---

## 14. 资源与推荐阅读

### 14.1 知识库引用(从本次研究)

| ID | 标题 | 为什么读 |
|---|---|---|
| [37795] | 加拿大程序员 $20→$60K MRR | Mac/Web indie 的反共识技术栈 + 6 产品组合策略 |
| [19118] | 哥飞《月入 4w 刀 万字记录》 | 出海 web 完整复盘,新手避坑 |
| [218025] | 哥飞《养网站如种果树》 | SEO 慢工夫,半年才见流量爆发 |
| [37917] | 刘小排《2 小时 Build 啥产品》 | indie 产品挖掘的 BuilderPulse 工具 |
| [49797] | Will GenAI 网页产品数据 | 海外产品流量榜单实时数据 |
| [217685] | AI 异类弗兰克《一人公司 3 个数字员工》 | 一人公司架构,营销自动化 |
| [157] | 硅谷101《一人企业全球生意》 | 单核公司商业模式 |

### 14.2 必读外部资源

**书籍:**
- 📕 Pieter Levels 《Make》— indie 出海圣经 (https://makebook.io)
- 📕 DHH 《Rework》— 反潮流的 indie 公司哲学
- 📕 Tony Fadell 《Build》— 产品力本质

**社区:**
- 🌐 [Indie Hackers](https://www.indiehackers.com) — 实操社区,搜 "Mac app revenue"
- 🌐 [Hacker News](https://news.ycombinator.com) — Show HN tag
- 🌐 [Reddit r/macapps](https://reddit.com/r/macapps)
- 🌐 [Pieter Levels Twitter](https://twitter.com/levelsio) — 实时 indie 案例

**工具/平台文档:**
- 📖 [Paddle Docs](https://developer.paddle.com)
- 📖 [Lemon Squeezy China Sellers](https://www.lemonsqueezy.com)
- 📖 [Setapp Developer](https://setapp.com/devs)
- 📖 [Apple Developer · Notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

**博客 / 案例:**
- 🏠 [levels.io](https://levels.io) — 每个产品 ARR 公开
- 🏠 [marclou.com](https://marclou.com) — Shipfa.st 收入透明
- 🏠 [pieterlevels.com](https://pieterlevels.com) — 同上
- 🏠 [lainevisualnotes.com/macos-developer-blog](https://laine.studio) — Mac 独立开发者博客

### 14.3 国内资源

- 微信公众号: 哥飞、刘小排r、AI 异类弗兰克、郎瀚威 Will
- 知乎话题: 独立开发者 / 跨境收款 / 海外软件销售
- V2EX 节点: indie 节点 / 创业 节点
- 少数派文章: 搜 "独立开发者" + "macOS 收费"

---

## 15. 决策记录

| 日期 | 决策 | 理由 |
|---|---|---|
| 2026-04-22 | 从 Electron 全面迁移到 Swift/SwiftUI | 原生体积小、性能好、符合 macOS 生态 |
| 2026-05-04 | 注册 Apple Developer Program ($99/年) | 海外发布必须的签名公证基础 |
| 2026-05-04 | 不买 melliefan.com,用 github.io 免费 | 个人站不需要包装,产品才需独立域名 |
| 2026-05-04 | 主市场:海外;副市场:国内小红书 | 国内 macOS 几乎不付费,海外是真实市场 |
| 2026-05-04 | 商业模式:$9 一次性买断 + Setapp 副渠道 | HN/PH 用户对订阅疲劳极度反感,工具类适合一次性 |
| 2026-05-04 | 收款:Paddle (主) + Lemon Squeezy (备) | MoR 模式让中国 indie 出海最简化 |
| 2026-05-04 | 主体:个人 → 月收 $3K 后注册个体工商户 | 阶段化匹配,不超前投入 |
| 2026-05-04 | 售后:Email + GitHub Issues,不开 Discord | 1K 用户以下 Discord 是负担 |
| 2026-05-04 | Nook i18n 推迟到 v1.5 后 | 116 条硬编码字符串,先发英文友好(品牌名+关键 UI 易懂)+用截图传达 |

---

## 附录:Nook 之外 — 持续推软件的长期视角

> 这部分是给未来的你看的。

### 不要梭哈一个产品

- Steve Hanov 18 年 6 个产品,每 3-5 年加一个
- 单产品风险 = 100%,组合产品风险 = 40-60%
- Nook 是第一个,validate 这条路是否走得通,但不要因为 Nook 而停下

### 时间是 indie 最大的护城河

- websequencediagrams 2008 年至今统治 Google "sequence diagram" 第一名
- 不要追新词,做永久需求(待办、笔记、日历、读书、计算)
- 复利在 indie 上比在职场强 10×

### 多产品共享底层

- 你的 Swift/SwiftUI 经验、Paddle 集成、签名流水线、营销渠道,都可以复用
- 第二个 macOS 工具 build 时间会从 6 个月 → 2 个月
- 第三个 → 1 个月

### 健康永远第一

- "持续推软件" 的关键是"持续"
- 一次梭哈一个月 burnout 比慢慢做一年危险
- 守住每周 10-15 小时 indie 时间,不要超

### 抗周期组合

- B2B 经济好时赚钱(企业预算大)
- C 端经济差时赚钱(用户省钱 DIY 工具)
- Nook 是 C 端工具,未来加个 B2B 产品(团队版?CMS 工具?)抗周期

---

**END.** 这是 v1.0,执行中持续迭代。每个 Day 30/60/90 决策门完成后,回到这个文档更新数字、修正预测、记录新决策。

*Last updated: 2026-05-04 by melliefan + Claude*
