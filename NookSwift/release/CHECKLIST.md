# Nook 发版 Checklist

每次发版前过一遍这个清单。复制到当次 release issue / 笔记里勾选。

---

## Pre-flight(发版前 1-3 天)

### 代码层

- [ ] 所有计划功能/bug fix 都 merge 到 main
- [ ] `bash build.sh` 全部 360+ 测试通过
- [ ] 浏览器/真机手测核心交互(hot corner / add task / sync / settings)
- [ ] 检查 console 无报错
- [ ] 没有 TODO 注释/调试代码混入(grep "FIXME" "TODO" "XXX")

### 版本号 + Changelog

- [ ] `Resources/Info.plist` 的 `CFBundleShortVersionString` 升级(v1.0.0 → v1.0.1)
- [ ] `Resources/Info.plist` 的 `CFBundleVersion` 升级(整数,递增)
- [ ] `CHANGELOG.md` 加新版本条目(如还没有该文件,创建)
- [ ] 网站 nook 页面的版本号同步更新(`v1.0.0` 在 hero/download)

### 法律/合规

- [ ] Privacy Policy 是否需要更新(新加了任何数据收集?)
- [ ] Terms of Service 是否需要更新
- [ ] Refund Policy 仍然适用

---

## Release(执行)

### 1. 跑 release 脚本

```bash
cd NookSwift
bash release/release.sh
```

- [ ] 9 步全部通过(无 error)
- [ ] 输出路径:`build/Nook.app` + `build/Nook.dmg`
- [ ] 记录 SHA-256(贴到下面)

```
SHA-256: ___________________________________________
```

### 2. 真机验证

- [ ] 把 DMG **拷到另一台干净 Mac** 或新建 macOS 测试用户
- [ ] 双击 DMG 不弹"无法验证开发者"警告 ✅
- [ ] 拖到 /Applications 后双击启动正常
- [ ] hot corner 触发正常
- [ ] 数据持久化正常(写一个任务,关掉,再开,数据还在)
- [ ] 提醒事项同步(若启用)正常

### 3. GitHub Release

- [ ] 打 tag:`git tag v1.0.0 && git push --tags`
- [ ] 在 https://github.com/melliefan/Nook/releases 创建 release
- [ ] 上传 `Nook.dmg` 到 release assets
- [ ] release notes 用 CHANGELOG 内容,带 SHA-256

### 4. 网站更新

- [ ] `melliefan.github.io/nook/index.html` 下载链接指向新 DMG(GitHub Release URL)
- [ ] SHA-256 在 download section 显示新值
- [ ] 如有破坏性变化,加 "Migration Guide" link
- [ ] commit + push,等 ~30s GitHub Pages 部署完毕

### 5. 验证线上

- [ ] 访问 https://melliefan.github.io/nook/ 检查 hero/version 显示正确
- [ ] 点击 "Download" 按钮,下载流程通畅
- [ ] DMG 实际大小 + SHA-256 跟你本地一致

---

## 发布(Day 0)

### 主推渠道

- [ ] **Hacker News Show HN** 帖子
  - 时段:美东时间周二/周三早 7-9am
  - 标题:`Show HN: Nook v1.0 – A macOS hot-corner todo list`
  - 链接:个人网站 melliefan.github.io/nook/(不是 GitHub),贴 GitHub URL 在 self-text
  - 准备好前 3 小时蹲守评论区

- [ ] **Product Hunt** 上线
  - 时段:太平洋时间周二/周三 12:01am
  - 提前一周 Schedule
  - First comment 草稿准备好

- [ ] **Reddit r/macapps** 帖子
  - 时段:周末晚上美东 9-11pm
  - 700 字 self-text + 3-5 张截图
  - 同步发 r/macOSBeta

### 次推渠道

- [ ] X/Twitter launch thread(5-7 条,每条带视觉)
- [ ] dev.to 文章("How I built X with Y")
- [ ] Indie Hackers Milestones 帖子
- [ ] 个人邮件:给 5-10 位认识的 indie/Mac 用户朋友推送

### 国内副线

- [ ] 小红书发 1-2 篇笔记
- [ ] 朋友圈一条(含截图 + 简短文案)
- [ ] V2EX `创意板` 发帖(如适合)

---

## 发布后(Day 1-7)

### 监控

- [ ] HN 帖子的位置(Day 1 抢首页,Day 2 仍可加分)
- [ ] PH 当日排名(争 Top 10 of the Day)
- [ ] Paddle 订单仪表盘(每天看)
- [ ] Google Analytics(网站访问数据)
- [ ] GitHub Stars / Issues
- [ ] Twitter 提及

### 响应

- [ ] HN 评论区每条认真回(尤其负面反馈,展示态度)
- [ ] Twitter 回复 launch thread 的人
- [ ] Email 收到的反馈 24-48h 内回
- [ ] GitHub Issues 24-72h 内 triage

### 修复

- [ ] 收集 Day 1-3 反馈,优先修破坏性 bug
- [ ] 评估 v1.0.1 patch 必要性(如有 ≥10 人报同一个 bug)

---

## 复盘(Day 7+)

- [ ] 写 launch retro(私版 + 公开版)
- [ ] 数据快照保存:HN 最高分/PH 最高排名/Day 1-7 销量/最大流量来源
- [ ] 更新 BUSINESS_PLAN.md §13 财务实际值 vs 预测
- [ ] 决策门(参考 BUSINESS_PLAN.md §10 的 Day 30 节点)

---

## 紧急回滚预案

若发现 critical bug 或公证后 DMG 在用户机器上跑不起来:

1. **立刻** 在网站 download section 加警告条 + 引导到 v1.0.x-1
2. **3-6 小时内** 出 v1.0.x+1 hot fix(走完整 release.sh 流程)
3. 给已购买用户发 email 通知 + 致歉
4. HN/PH/Reddit 回评论解释
5. 复盘:这个 bug 为什么 release 前没发现?加测试

---

*这个 checklist 保持更新。每发一版找到没覆盖的坑,加进来。*
