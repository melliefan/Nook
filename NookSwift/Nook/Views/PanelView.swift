import AppKit
import SwiftUI

struct NookVisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct PanelView: View {
    private enum EditorMode: Equatable {
        case new
        case edit(Int)
    }

    @ObservedObject var store: Store
    @ObservedObject var panelController: PanelController
    @State private var editorMode: EditorMode?
    @State private var showSettings = false
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("nook_appearance") private var appearance: String = "light"

    private var corner: NookSettings.CornerTrigger { store.settings.cornerTrigger }

    /// SwiftUI-native color scheme override.
    /// nil = follow system (when appearance == "system"), otherwise force.
    /// This ensures the panel re-renders correctly without relying on
    /// NSApp.appearance propagation through NSPanel/NSHostingView.
    private var forcedColorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil   // follow system
        }
    }

    var body: some View {
        ZStack {
            // HTML uses opaque var(--bg) so backdrop-filter is invisible.
            // Match by filling solid; keep NSVisualEffect under for native edge bleed only.
            NookVisualEffectBackground()
                .clipShape(RoundedRectangle(cornerRadius: 14))

            RoundedRectangle(cornerRadius: 14)
                .fill(NookTheme.bg(colorScheme))

            if let editorMode {
                switch editorMode {
                case .new:
                    TaskDetailView(store: store, taskId: nil) { closeEditor() }
                        .transition(.move(edge: .trailing))
                case .edit(let taskId):
                    TaskDetailView(store: store, taskId: taskId) { closeEditor() }
                        .transition(.move(edge: .trailing))
                }
            } else {
                listContent
                    .transition(.move(edge: store.settings.cornerTrigger.isRight ? .trailing : .leading))
            }

            ConfettiBurst(token: store.confettiToken)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(NookTheme.panelBorder(colorScheme), lineWidth: 1)
        )
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.4) : Color(hex: "#1E1E2A").opacity(0.08),
            radius: 20,
            x: 0,
            y: 12
        )
        .preferredColorScheme(forcedColorScheme)
    }

    private func openEditor(_ mode: EditorMode) {
        withAnimation(.easeInOut(duration: 0.25)) {
            editorMode = mode
        }
    }

    private func closeEditor() {
        withAnimation(.easeInOut(duration: 0.25)) {
            editorMode = nil
        }
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            HeaderView(
                store: store,
                panelController: panelController,
                showSettings: $showSettings,
                onAdd: { openEditor(.new) }
            )

            TagFilterBarView(store: store)
                .transaction { $0.animation = nil }

            TaskListView(store: store) { taskId in
                openEditor(.edit(taskId))
            }

            SnippetsSectionView(store: store)

            AttributionView()
        }
    }
}

// MARK: - Cursor Helpers

extension NSCursor {
    /// macOS uses private cursors for diagonal window-resize edges. Reach for them
    /// reflectively — falls back to crosshair if the selector ever goes away.
    static var nookDiagonalNESW: NSCursor {
        privateCursor("_windowResizeNorthEastSouthWestCursor") ?? .crosshair
    }

    static var nookDiagonalNWSE: NSCursor {
        privateCursor("_windowResizeNorthWestSouthEastCursor") ?? .crosshair
    }

    private static func privateCursor(_ name: String) -> NSCursor? {
        let sel = NSSelectorFromString(name)
        guard NSCursor.responds(to: sel),
              let unmanaged = NSCursor.perform(sel) else { return nil }
        return unmanaged.takeUnretainedValue() as? NSCursor
    }
}

// MARK: - Header

struct HeaderView: View {
    @ObservedObject var store: Store
    @ObservedObject var panelController: PanelController
    @Binding var showSettings: Bool
    let onAdd: () -> Void
    @State private var showSortMenu = false
    @Environment(\.colorScheme) private var colorScheme

    private var dateTitle: String {
        let d = Date()
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d · EEEE"
        return f.string(from: d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 7) {
                    Text("Inbox")
                        .font(.nook(size: 22, weight: .heavy))
                        .foregroundStyle(NookTheme.t1(colorScheme))
                        .tracking(-0.45)

                    let activeCount = store.tasks.filter { !$0.completed }.count
                    if activeCount > 0 {
                        Text("\(activeCount)")
                            .font(.nook(size: 11, weight: .semibold))
                            .foregroundStyle(NookTheme.accent(colorScheme))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(NookTheme.blueBg(colorScheme)))
                    }
                }

                Spacer()

                HStack(spacing: 1) {
                    headerButton(icon: .plus, size: 18, kind: .lite) {
                        onAdd()
                    }
                    headerButton(icon: .pin, size: 16, kind: panelController.isPinned ? .active : .normal) {
                        panelController.togglePin()
                    }
                    headerButton(icon: .sort, size: 16) {
                        showSortMenu.toggle()
                    }
                    .popover(isPresented: $showSortMenu, arrowEdge: .bottom) {
                        SortMenuView(store: store)
                    }
                    headerButton(icon: .gear, size: 16) {
                        showSettings.toggle()
                    }
                    .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                        SettingsPopoverView(store: store)
                    }
                    headerButton(icon: .sidebarLeft, size: 16) {
                        panelController.isPinned = false
                        panelController.hide()
                    }
                    .help("Hide panel (Nook keeps running, hot corner brings it back. Quit fully via Settings.)")
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .padding(.bottom, 12)
    }

    private func headerButton(icon: NookIconName, size: CGFloat, kind: HeaderIconButton.Kind = .normal, action: @escaping () -> Void) -> some View {
        HeaderIconButton(icon: icon, size: size, kind: kind, action: action)
    }
}

private struct HeaderIconButton: View {
    enum Kind { case normal, lite, active }
    let icon: NookIconName
    let size: CGFloat
    let kind: Kind
    let action: () -> Void
    @State private var isHovering = false
    @Environment(\.colorScheme) private var colorScheme

    private var fg: Color {
        switch kind {
        case .lite, .active: return NookTheme.accent(colorScheme)
        case .normal: return isHovering ? NookTheme.t2(colorScheme) : NookTheme.t3(colorScheme)
        }
    }

    private var bg: Color {
        switch kind {
        case .active: return NookTheme.blueBg(colorScheme)
        case .lite: return isHovering ? NookTheme.blueBg(colorScheme) : Color.clear
        case .normal: return isHovering ? NookTheme.bgHover(colorScheme) : Color.clear
        }
    }

    var body: some View {
        Button(action: action) {
            NookIcon(icon, size: size)
                .foregroundStyle(fg)
                .frame(width: 30, height: 30)
                .background(bg, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Sort Menu

struct SortMenuView: View {
    @ObservedObject var store: Store
    @AppStorage("nook_sort") private var currentSort = "custom"
    @Environment(\.colorScheme) private var colorScheme

    private let options: [(key: String, label: String, icon: NookIconName)] = [
        ("custom", "Manual order", .drag),
        ("priority", "By priority", .flag),
        ("dueDate", "By due date", .calendar),
        ("title", "By title", .doc),
        ("created", "By date created", .clock),
    ]

    var body: some View {
        VStack(spacing: 2) {
            ForEach(options, id: \.key) { opt in
                Button {
                    currentSort = opt.key
                } label: {
                    HStack(spacing: 8) {
                        NookIcon(opt.icon, size: 13)
                            .frame(width: 18)
                        Text(opt.label)
                            .font(.nook(size: 13))
                        Spacer()
                        if currentSort == opt.key {
                            NookIcon(.checkmark, size: 11)
                                .foregroundStyle(NookTheme.accent(colorScheme))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .frame(width: 180)
    }
}

// MARK: - Attribution

struct AttributionView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            // Use the actual app icon (the user's downloaded logo) — not a synthesized
            // glyph on a colored block.
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .interpolation(.high)
                .frame(width: 30, height: 30)
            Text("Nook")
                .font(.nook(size: 11, weight: .semibold))
                .foregroundStyle(NookTheme.t2(colorScheme))
            Text("·")
                .font(.nook(size: 8))
                .foregroundStyle(NookTheme.t4(colorScheme))
            Text("Triggered by hot corner")
                .font(.nook(size: 10))
                .foregroundStyle(NookTheme.t3(colorScheme))
            Spacer()
            Text("v1.0.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(NookTheme.t4(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.top, 9)
        .padding(.bottom, 11)
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = URL(string: "https://github.com/melliefan/Nook") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
