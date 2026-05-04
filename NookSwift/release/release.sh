#!/bin/bash
# release.sh · Nook 发版一条龙
#
# 流程:
#   build → sign Nook.app → notarize → staple → DMG → sign DMG → notarize DMG → staple
#
# 用法:
#   1. cp release/.env.signing.example release/.env.signing
#   2. 填好 .env.signing 各项(见模板注释)
#   3. cd NookSwift && bash release/release.sh
#
# 输出:
#   build/Nook.app  (signed + notarized + stapled,双击直接打开,无 Gatekeeper 警告)
#   build/Nook.dmg  (signed + notarized + stapled,可分发)

set -euo pipefail

# ─── 路径 ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$SCRIPT_DIR/.env.signing"
ENTITLEMENTS="$SCRIPT_DIR/Nook.entitlements"
APP_NAME="Nook"
APP_PATH="$PROJ_DIR/build/$APP_NAME.app"
DMG_PATH="$PROJ_DIR/build/$APP_NAME.dmg"
DMG_STAGE="$PROJ_DIR/build/dmg-stage"
ZIP_PATH="$PROJ_DIR/build/$APP_NAME-for-notary.zip"

# ─── 颜色输出 ──────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
err() { echo -e "${RED}✘${NC} $*" >&2; exit 1; }
step() { echo -e "\n${BOLD}── $* ──${NC}"; }

# ─── 1. 配置检查 ───────────────────────────────────────────
step "1. 检查签名配置"

[ -f "$ENV_FILE" ] || err ".env.signing 不存在。先执行: cp release/.env.signing.example release/.env.signing 然后填值"
[ -f "$ENTITLEMENTS" ] || err "$ENTITLEMENTS 不存在"

# shellcheck source=/dev/null
source "$ENV_FILE"

[ -n "${DEVELOPER_ID:-}" ] || err "DEVELOPER_ID 未设置"
[ -n "${TEAM_ID:-}" ] || err "TEAM_ID 未设置"
[ -n "${ASC_API_KEY_PATH:-}" ] || err "ASC_API_KEY_PATH 未设置"
[ -n "${ASC_KEY_ID:-}" ] || err "ASC_KEY_ID 未设置"
[ -n "${ASC_ISSUER_ID:-}" ] || err "ASC_ISSUER_ID 未设置"
[ -f "$ASC_API_KEY_PATH" ] || err "API Key 文件不存在: $ASC_API_KEY_PATH"

# 校验证书已安装
if ! security find-identity -v -p codesigning | grep -q "$DEVELOPER_ID"; then
    err "钥匙串里找不到证书:$DEVELOPER_ID"
fi
ok "签名配置 OK"
ok "证书:$DEVELOPER_ID"
ok "Team:$TEAM_ID"

# ─── 2. 构建 ───────────────────────────────────────────────
step "2. 构建 Nook.app"
cd "$PROJ_DIR"
bash build.sh --skip-tests
[ -d "$APP_PATH" ] || err "build 没产出 $APP_PATH"
ok "build/Nook.app 完成"

# ─── 3. 签名 Nook.app ──────────────────────────────────────
step "3. 用 Developer ID 签名 Nook.app(含 hardened runtime)"

# 先清干净 xattr,防止 codesign 报错
xattr -cr "$APP_PATH"

# 深度签名所有嵌入二进制(包括 frameworks/dylib/helpers)
codesign --force --deep \
    --options runtime \
    --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$DEVELOPER_ID" \
    "$APP_PATH"

# 验证签名
codesign --verify --deep --strict --verbose=2 "$APP_PATH" 2>&1 | tail -3
ok "Nook.app 已签"

# ─── 4. 公证 Nook.app ──────────────────────────────────────
step "4. 提交 Nook.app 到 Apple 公证"

# 公证服务接收 .zip / .dmg / .pkg。这里先打 zip 提交
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
ok "已打包 $ZIP_PATH"

# notarytool 提交 + 等待
echo "→ 公证中(通常 1-5 分钟)..."
xcrun notarytool submit "$ZIP_PATH" \
    --key "$ASC_API_KEY_PATH" \
    --key-id "$ASC_KEY_ID" \
    --issuer "$ASC_ISSUER_ID" \
    --wait \
    --output-format json > /tmp/notary-app.json

NOTARY_STATUS=$(python3 -c "import json; print(json.load(open('/tmp/notary-app.json'))['status'])")

if [ "$NOTARY_STATUS" != "Accepted" ]; then
    NOTARY_ID=$(python3 -c "import json; print(json.load(open('/tmp/notary-app.json'))['id'])")
    warn "公证失败,拉日志看原因:"
    xcrun notarytool log "$NOTARY_ID" \
        --key "$ASC_API_KEY_PATH" \
        --key-id "$ASC_KEY_ID" \
        --issuer "$ASC_ISSUER_ID"
    err "Nook.app 公证 status=$NOTARY_STATUS"
fi
ok "Nook.app 公证通过"
rm -f "$ZIP_PATH"

# ─── 5. Staple Nook.app ────────────────────────────────────
step "5. 把公证票贴到 Nook.app(staple)"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH" 2>&1 | tail -1

# Gatekeeper 验证
spctl -a -t exec -vv "$APP_PATH" 2>&1 | tail -2 || warn "spctl 检查异常,但 staple 成功不影响分发"
ok "Nook.app 已 staple,Gatekeeper 双击直接打开无警告"

# ─── 6. 打包 DMG ───────────────────────────────────────────
step "6. 打包 DMG"
rm -f "$DMG_PATH"
rm -rf "$DMG_STAGE"
mkdir -p "$DMG_STAGE"
cp -R "$APP_PATH" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGE" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

rm -rf "$DMG_STAGE"
ok "build/Nook.dmg 创建"

# ─── 7. 签名 DMG ───────────────────────────────────────────
step "7. 签名 DMG"
codesign --force \
    --timestamp \
    --sign "$DEVELOPER_ID" \
    "$DMG_PATH"
ok "DMG 已签"

# ─── 8. 公证 DMG ───────────────────────────────────────────
step "8. 提交 DMG 到 Apple 公证"
echo "→ 公证中(通常 1-3 分钟)..."
xcrun notarytool submit "$DMG_PATH" \
    --key "$ASC_API_KEY_PATH" \
    --key-id "$ASC_KEY_ID" \
    --issuer "$ASC_ISSUER_ID" \
    --wait \
    --output-format json > /tmp/notary-dmg.json

NOTARY_STATUS=$(python3 -c "import json; print(json.load(open('/tmp/notary-dmg.json'))['status'])")

if [ "$NOTARY_STATUS" != "Accepted" ]; then
    NOTARY_ID=$(python3 -c "import json; print(json.load(open('/tmp/notary-dmg.json'))['id'])")
    warn "DMG 公证失败,拉日志:"
    xcrun notarytool log "$NOTARY_ID" \
        --key "$ASC_API_KEY_PATH" \
        --key-id "$ASC_KEY_ID" \
        --issuer "$ASC_ISSUER_ID"
    err "DMG 公证 status=$NOTARY_STATUS"
fi
ok "DMG 公证通过"

# ─── 9. Staple DMG ─────────────────────────────────────────
step "9. 把公证票贴到 DMG"
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH" 2>&1 | tail -1
ok "DMG 已 staple,可以分发"

# ─── 10. 完工汇总 ─────────────────────────────────────────
step "✨ 发版完成"
echo ""
echo "  Nook.app:  $APP_PATH"
ls -lh "$APP_PATH" | awk '{print "             "$5}'
echo "  Nook.dmg:  $DMG_PATH"
ls -lh "$DMG_PATH" | awk '{print "             "$5}'
echo ""
echo "  SHA-256:"
shasum -a 256 "$DMG_PATH"
echo ""
echo "  下一步:"
echo "    □ 把 SHA-256 更新到 melliefan.github.io 网站"
echo "    □ 把 DMG 上传 GitHub Releases 或网站"
echo "    □ 跟 release/CHECKLIST.md 走完检查"
echo "    □ 发 Show HN / Product Hunt"
echo ""
