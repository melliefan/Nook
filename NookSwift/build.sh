#!/bin/bash
set -e
cd "$(dirname "$0")"

# Run tests first
if [ "$1" != "--skip-tests" ]; then
  echo "🧪 Running tests..."
  xcrun swiftc \
    -target arm64-apple-macosx14.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework SwiftUI -framework AppKit -framework CoreGraphics \
    -parse-as-library \
    -o test_runner \
    $(find Nook -name "*.swift" -not -name "NookApp.swift" -type f) \
    $(find Tests -name "*.swift" -type f) \
    2>&1
  ./test_runner 2>&1
  echo ""
fi

echo "🔨 Compiling Nook (Swift)..."
xcrun swiftc \
  -target arm64-apple-macosx14.0 \
  -sdk "$(xcrun --show-sdk-path)" \
  -framework SwiftUI -framework AppKit -framework CoreGraphics \
  -parse-as-library \
  -O \
  -o Nook_bin \
  $(find Nook -name "*.swift" -type f)

APP_DIR="build/Nook.app/Contents"
mkdir -p "$APP_DIR/MacOS" "$APP_DIR/Resources"
cp Nook_bin "$APP_DIR/MacOS/Nook"
cp Nook/Resources/Info.plist "$APP_DIR/"
cp -R Nook/Resources/Assets.xcassets "$APP_DIR/Resources/" 2>/dev/null || true

# Bundle the nooktodo CLI script — installed via Settings popover
if [ -f scripts/nooktodo ]; then
  cp scripts/nooktodo "$APP_DIR/Resources/nooktodo"
  chmod 755 "$APP_DIR/Resources/nooktodo"
fi

# Bundle the empty-state illustration
if [ -f Nook/Resources/empty-state.png ]; then
  cp Nook/Resources/empty-state.png "$APP_DIR/Resources/empty-state.png"
fi

# Copy app icon from Electron build if available
ICON_SRC="../build/icon.icns"
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$APP_DIR/Resources/AppIcon.icns"
fi

SIZE=$(du -sh build/Nook.app | cut -f1)
echo "✅ Build complete: build/Nook.app ($SIZE)"
echo ""
echo "Run:  open build/Nook.app"
echo "  or: ./build/Nook.app/Contents/MacOS/Nook"
