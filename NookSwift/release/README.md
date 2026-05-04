# NookSwift release pipeline

Release/发布相关脚本和文档。设计目标是**跨 indie 产品复用** — 将来做第二个 macOS app,这套基本能直接拷过去改个名。

## 内容

| 文件 | 用途 |
|---|---|
| `release.sh` | 一条龙发版脚本(build → sign → notarize → DMG) |
| `Nook.entitlements` | Hardened runtime entitlements(空,无例外) |
| `.env.signing.example` | 签名/公证配置模板 |
| `.env.signing` | **真实配置**(gitignored,不进库) |
| `CHECKLIST.md` | 每次发版的清单 |
| `README.md` | 本文件 |

## 第一次使用

### 1. 拿到 Apple Developer 资格(必须先有)

- 注册 Apple Developer Program ($99/年)
- 等账号激活(~1-2 天)

### 2. 创建 Developer ID Application 证书

- 后台 → Certificates → 新建
- 选 "Developer ID Application"
- 本机生成 CSR(Keychain Access → Certificate Assistant → "Request a Certificate from a Certificate Authority")
- 上传 CSR → 下载 `.cer` → 双击导入钥匙串

验证:
```bash
security find-identity -v -p codesigning
```
应该看到一行包含 `Developer ID Application: <你的名字> (XXXXXXXXXX)`。

### 3. 创建 App Store Connect API Key(用于公证)

- https://appstoreconnect.apple.com/access/api
- 新建 → 角色选 **Developer**(权限够用)
- 下载 `.p8` 文件,**只能下载一次**,妥善保存
- 记下 **Key ID** 和 **Issuer ID**

### 4. 配置 .env.signing

```bash
cd release/
cp .env.signing.example .env.signing
# 编辑 .env.signing 填入真实值
```

填的字段:
- `DEVELOPER_ID` — 钥匙串里证书的完整 Common Name
- `TEAM_ID` — 10 位字符
- `ASC_API_KEY_PATH` — `.p8` 文件本地绝对路径
- `ASC_KEY_ID` — Key ID
- `ASC_ISSUER_ID` — UUID 格式的 Issuer ID

### 5. 跑 release.sh

```bash
cd NookSwift
bash release/release.sh
```

时间预估:
- 构建:~10 秒
- 签名:~5 秒
- 公证 Nook.app:1-5 分钟(Apple 服务器决定)
- Staple:< 5 秒
- DMG 打包:~5 秒
- 公证 DMG:1-3 分钟
- Staple DMG:< 5 秒

**总计 ~5-15 分钟**。

## 后续发版

第一次配置好之后,每次发版只需:

1. 改代码 → push
2. 升 `Info.plist` 版本号
3. `bash release/release.sh`
4. 跟 `CHECKLIST.md` 走一遍
5. 上传 DMG 到 GitHub Releases / 网站
6. 发布

## 复用到下一个产品

下一个 indie macOS 产品的 release 流程,把这套拷过去:

```bash
cp -r NookSwift/release NewProductSwift/release
cd NewProductSwift/release
# 改两处:
#  - Nook.entitlements → NewProduct.entitlements (除非 entitlements 不同)
#  - release.sh 里 APP_NAME="Nook" → APP_NAME="NewProduct"
# .env.signing 跟 Nook 复用同一份(同一个 Apple Developer 账号)
```

## Troubleshooting

### "Code signing failed: no identity found"
钥匙串里没装 Developer ID Application 证书。回到上面 §2 重新走。

### "errSecInternalComponent"
签名时 Keychain 锁了。`security unlock-keychain` 解锁,或者直接 GUI 输密码。

### 公证 returned status: Invalid
拿日志看具体原因:
```bash
xcrun notarytool log <SUBMISSION_ID> \
    --key "$ASC_API_KEY_PATH" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID"
```
常见原因:
- 没启用 hardened runtime → release.sh 已加 `--options runtime`
- 没 timestamp 签名 → release.sh 已加 `--timestamp`
- 嵌入的二进制没全签 → release.sh 用 `--deep`

### Staple 失败 "The validate action found no errors"
Staple 之前公证票还没完全到位,稍等 1 分钟重试。

### Gatekeeper spctl 报 "rejected"
但 staple 成功了。如果 staple OK,实际分发不会触发 Gatekeeper 警告。可以忽略 spctl 报错。

---

## 设计决策记录

**为什么 release.sh 是 bash 而不是 fastlane / Xcode build phase?**
- 跨产品复用最方便(一份脚本走天下)
- Bash 透明,出问题好 debug
- 没有外部依赖(fastlane 要 Ruby + 一堆 gem)

**为什么不用 GitHub Actions 自动化?**
- 现在产品体量小,本地手动 release 完全够用
- 用 Apple Developer 证书在 CI 上跑要存 secrets,复杂度高
- 等做到第三个产品再考虑 GHA(此时 ROI 才正)

**为什么 entitlements 是空的?**
- Nook 不需要任何 hardened runtime 例外
- 沙盒 OFF(hot corner 用 CGEvent.tapCreate,沙盒禁止)
- Reminders 通过 Info.plist `NSRemindersUsageDescription` 走运行时授权
- Accessibility 通过用户首次使用时系统弹窗授权

**为什么用 App Store Connect API Key 而不是 Apple ID + app-specific password?**
- API Key 更稳(不受密码改动影响)
- 能精细控制权限
- Apple 推荐(notarytool 文档第一选项)
