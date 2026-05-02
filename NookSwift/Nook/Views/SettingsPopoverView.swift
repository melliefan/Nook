import SwiftUI

struct SettingsPopoverView: View {
    @ObservedObject var store: Store
    @AppStorage("nook_appearance") private var appearance: String = "system"

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
                                    .fill(appearance == value ? Color.blue : Color.clear)
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
                                .fill(store.settings.cornerTrigger == corner ? Color.blue.opacity(0.1) : Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(store.settings.cornerTrigger == corner ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(width: 200)
        .onAppear {
            applyAppearance(appearance)
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
                .fill(store.settings.cornerTrigger == corner ? Color.blue : Color.secondary.opacity(0.4))
                .frame(width: 5, height: 5)
                .offset(
                    x: corner.isRight ? size / 2 - 5 : -size / 2 + 5,
                    y: corner.isBottom ? size * 0.35 - 5 : -size * 0.35 + 5
                )
        }
    }
}
