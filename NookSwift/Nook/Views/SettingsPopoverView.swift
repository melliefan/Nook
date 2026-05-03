import SwiftUI

struct SettingsPopoverView: View {
    @ObservedObject var store: Store
    @AppStorage("nook_appearance") private var appearance: String = "system"
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
                            .foregroundStyle(appearance == value ? .white : .primary)
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
                Text("在终端中操作待办：复制下方一键安装命令到 Terminal 执行即可。")
                    .font(.nook(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(#"nooktodo "买牛奶" -t 购物 -p high"#)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
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
                    .foregroundStyle(.white)
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

    private func copyInstallCommand() {
        // Use the bundled script's actual on-disk path so the install works regardless
        // of where the user dragged Nook.app to.
        let scriptPath = Bundle.main.url(forResource: "nooktodo", withExtension: nil)?.path
            ?? "/Applications/Nook.app/Contents/Resources/nooktodo"
        let cmd = """
        mkdir -p ~/.local/bin && \
        cp "\(scriptPath)" ~/.local/bin/nooktodo && \
        chmod +x ~/.local/bin/nooktodo && \
        echo '✓ 已安装到 ~/.local/bin/nooktodo' && \
        echo '如果命令找不到，请把 ~/.local/bin 加入 PATH:' && \
        echo "  echo 'export PATH=\\"\\$HOME/.local/bin:\\$PATH\\"' >> ~/.zshrc"
        """
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
