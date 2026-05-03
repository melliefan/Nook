import SwiftUI

struct SettingsPopoverView: View {
    @ObservedObject var store: Store
    @AppStorage("nook_appearance") private var appearance: String = "light"
    @State private var copiedCli = false
    @Environment(\.colorScheme) private var colorScheme

    private let corners: [(NookSettings.CornerTrigger, String)] = [
        (.topLeft, "左上"), (.topRight, "右上"),
        (.bottomLeft, "左下"), (.bottomRight, "右下"),
    ]

    private let appearanceOptions: [(String, String)] = [
        ("system", "跟随系统"),
        ("light", "浅色"),
        ("dark", "深色"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nook 偏好")
                .font(.nook(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                ForEach(appearanceOptions, id: \.0) { value, label in
                    Button {
                        appearance = value
                        applyAppearance(value)
                    } label: {
                        Text(label)
                            .font(.system(size: 11, weight: appearance == value ? .semibold : .regular))
                            .foregroundStyle(appearance == value ? NookTheme.tagOnFg(colorScheme) : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(appearance == value ? NookTheme.accent(colorScheme) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.04))
            )

            Text("热角")
                .font(.nook(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(corners, id: \.0) { corner, label in
                    Button {
                        store.updateCorner(corner)
                    } label: {
                        VStack(spacing: 4) {
                            cornerDiagram(corner)
                            Text(label)
                                .font(.nook(size: 11))
                                .foregroundStyle(store.settings.cornerTrigger == corner ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(store.settings.cornerTrigger == corner ? Color.primary.opacity(0.08) : Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(store.settings.cornerTrigger == corner ? Color.primary.opacity(0.25) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("命令行工具")
                .font(.nook(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("装好后 Claude 等 AI 助手就能帮你记待办。把下面命令贴到 Terminal 跑一次即可。")
                    .font(.nook(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(installCommandPreview)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.05))
                    )

                Button {
                    copyInstallCommand()
                } label: {
                    HStack(spacing: 5) {
                        NookIcon(copiedCli ? .checkmark : .copy, size: 10)
                        Text(copiedCli ? "已复制到剪贴板" : "一键复制安装命令")
                            .font(.nook(size: 11, weight: .medium))
                    }
                    .foregroundStyle(NookTheme.tagOnFg(colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(NookTheme.accent(colorScheme))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 240)
        // Override macOS popover's translucent menu material with the panel's solid bg.
        .background(NookTheme.bg(colorScheme))
        .onAppear {
            applyAppearance(appearance)
        }
    }

    /// Display preview — short version of the actual command for visual hint.
    private var installCommandPreview: String {
        """
        # 自动找 Nook.app + 选 PATH 里的目录安装
        # 必要时还会把 ~/.local/bin 写进 .zshrc
        bash -c "$(...auto-install script...)"
        """
    }

    /// Full clipboard command — robust auto-install that:
    ///   1. Finds Nook.app via Spotlight-free `find`
    ///   2. Picks an install dir that's already in PATH (homebrew / /usr/local/bin)
    ///   3. Falls back to ~/.local/bin AND auto-appends export PATH to .zshrc
    /// So AI agents can run it once and `nooktodo` is immediately available.
    private func copyInstallCommand() {
        let cmd = #"""
        NOOK=$(find /Applications ~/Applications -name Nook.app -maxdepth 2 2>/dev/null | head -1)
        if [ -z "$NOOK" ]; then echo "✗ 找不到 Nook.app — 请先把它拖到 /Applications"; exit 1; fi
        SCRIPT="$NOOK/Contents/Resources/nooktodo"
        # 1. 优先找 PATH 里已存在且可写的目录
        TARGET=""
        for d in /opt/homebrew/bin /usr/local/bin; do
          if echo ":$PATH:" | grep -q ":$d:" && [ -w "$d" ] 2>/dev/null; then
            TARGET="$d"; break
          fi
        done
        # 2. 如果 PATH 里没现成可写目录，用 ~/.local/bin 并自动加进 .zshrc
        if [ -z "$TARGET" ]; then
          TARGET="$HOME/.local/bin"
          mkdir -p "$TARGET"
          RC="$HOME/.zshrc"; [ -n "$BASH_VERSION" ] && RC="$HOME/.bashrc"
          if ! echo ":$PATH:" | grep -q ":$TARGET:"; then
            { echo ""; echo "# Added by Nook"; echo "export PATH=\"\$HOME/.local/bin:\$PATH\""; } >> "$RC"
            echo "✓ 已把 ~/.local/bin 加入 PATH（写入 $RC，新开 Terminal 即可生效）"
          fi
        fi
        ln -sf "$SCRIPT" "$TARGET/nooktodo"
        export PATH="$TARGET:$PATH"
        echo "✓ nooktodo 已安装到 $TARGET/nooktodo"
        echo "✓ 当前 shell 立即可用：nooktodo 'test'"
        """#
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(cmd, forType: .string)
        copiedCli = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            copiedCli = false
        }
    }

    private func applyAppearance(_ mode: String) {
        switch mode {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }

    private func cornerDiagram(_ corner: NookSettings.CornerTrigger) -> some View {
        let size: CGFloat = 28
        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                .frame(width: size, height: size * 0.7)
            Circle()
                .fill(store.settings.cornerTrigger == corner ? Color.primary : Color.secondary.opacity(0.4))
                .frame(width: 5, height: 5)
                .offset(
                    x: corner.isRight ? size / 2 - 5 : -size / 2 + 5,
                    y: corner.isBottom ? size * 0.35 - 5 : -size * 0.35 + 5
                )
        }
    }
}
