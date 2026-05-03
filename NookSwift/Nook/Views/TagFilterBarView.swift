import SwiftUI

struct TagFilterBarView: View {
    @ObservedObject var store: Store
    @AppStorage("nook_filterTag") private var filterTag: String = ""
    @State private var showAddInput = false
    @State private var newTagName = ""
    @State private var isExpanded = false
    @State private var hoveredTag: String?
    @Environment(\.colorScheme) private var colorScheme

    private let maxCollapsedTags = 8

    private var allTagNames: [String] {
        let activeTags = Set(store.tasks.filter { !$0.completed }.flatMap(\.tags))
        let globalTags = Set(store.tags.keys)
        return Array(activeTags.union(globalTags)).sorted()
    }

    /// Tags to display based on expanded/collapsed state
    private var visibleTagNames: [String] {
        if isExpanded || allTagNames.count <= maxCollapsedTags {
            return allTagNames
        }
        return Array(allTagNames.prefix(maxCollapsedTags))
    }

    private var overflowCount: Int {
        max(0, allTagNames.count - maxCollapsedTags)
    }

    private var hasOverflow: Bool {
        allTagNames.count > maxCollapsedTags
    }

    var body: some View {
        if !allTagNames.isEmpty {
            WrappingHStack(spacing: 5, lineSpacing: 5) {
                tagChip(label: "all", color: nil, count: nil, isActive: filterTag.isEmpty) {
                    filterTag = ""
                }

                ForEach(visibleTagNames, id: \.self) { tag in
                    let color = displayColor(for: tag)
                    let count = store.tasks.filter { !$0.completed && $0.tags.contains(tag) }.count
                    tagChip(
                        label: tag,
                        color: color,
                        count: count > 0 ? count : nil,
                        isActive: filterTag == tag,
                        isHovered: hoveredTag == tag,
                        onDelete: {
                            if filterTag == tag { filterTag = "" }
                            hoveredTag = nil
                            store.deleteTag(tag)
                        }
                    ) {
                        filterTag = filterTag == tag ? "" : tag
                    }
                    .onHover { hovering in
                        if hovering { hoveredTag = tag }
                        else if hoveredTag == tag { hoveredTag = nil }
                    }
                    .contextMenu {
                        Button("删除标签", role: .destructive) {
                            if filterTag == tag { filterTag = "" }
                            store.deleteTag(tag)
                        }
                    }
                }

                if hasOverflow && !isExpanded {
                    moreOrFold(label: "+\(overflowCount)") {
                        withAnimation(.easeInOut(duration: 0.15)) { isExpanded = true }
                    }
                }

                if isExpanded || !hasOverflow {
                    if showAddInput {
                        TextField("标签名", text: $newTagName)
                            .textFieldStyle(.plain)
                            .font(.nook(size: 11))
                            .frame(width: 60, height: 24)
                            .padding(.horizontal, 10)
                            .background(NookTheme.bg2(colorScheme), in: Capsule())
                            .onSubmit { addTag() }
                            .onExitCommand { showAddInput = false; newTagName = "" }
                    } else {
                        Button {
                            showAddInput = true
                        } label: {
                            HStack(spacing: 4) {
                                NookIcon(.plus, size: 12)
                                Text("标签")
                                    .font(.nook(size: 11, weight: .medium))
                            }
                            .foregroundStyle(NookTheme.t2(colorScheme))
                            .frame(height: 24)
                            .padding(.horizontal, 10)
                            .background(NookTheme.bg2(colorScheme), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if hasOverflow && isExpanded {
                    moreOrFold(label: "收起") {
                        withAnimation(.easeInOut(duration: 0.15)) { isExpanded = false }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)
            .padding(.bottom, 8)
        }
    }

    private func moreOrFold(label: String, action: @escaping () -> Void) -> some View {
        Text(label)
            .font(.nook(size: 11, weight: .medium))
            .foregroundStyle(NookTheme.t2(colorScheme))
            .frame(height: 24)
            .padding(.horizontal, 10)
            .background(NookTheme.bg2(colorScheme), in: Capsule())
            .onTapGesture(perform: action)
    }

    // MARK: - Tag Chip

    /// HTML spec: height 24, font 11/500, padding 0 10, gap 4, dot 6×6.
    /// Inactive bg = tag color at ~10% opacity. Active bg = tagOn token.
    /// On hover: count 隐藏 → × 出现在同一槽位（不破坏 chip 宽度，不在 chip 外飘）
    private func tagChip(
        label: String, color: String?, count: Int?, isActive: Bool,
        isHovered: Bool = false, onDelete: (() -> Void)? = nil,
        onTap: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 4) {
            if let color, !isActive {
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 6, height: 6)
            }
            Text(label)
                .font(.nook(size: 11, weight: .medium))
            // ZStack 占位：count 和 × 重叠在同一槽位，opacity 切换显隐
            // → chip 宽度始终 = max(count 宽, × 宽)，hover 时不抖动 / 不重排
            if count != nil || onDelete != nil {
                ZStack {
                    if let count {
                        Text("\(count)")
                            .font(.nook(size: 10, weight: .medium))
                            .foregroundStyle(chipForeground(isActive: isActive).opacity(0.55))
                            .opacity(isHovered ? 0 : 1)
                    }
                    if onDelete != nil {
                        Button { onDelete?() } label: {
                            NookIcon(.x, size: 8)
                                .foregroundStyle(chipForeground(isActive: isActive).opacity(0.7))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .opacity(isHovered ? 1 : 0)
                        .allowsHitTesting(isHovered)
                        .help("删除标签")
                    }
                }
            }
        }
        .foregroundStyle(chipForeground(isActive: isActive))
        .frame(height: 24)
        .padding(.horizontal, 10)
        .background(Capsule().fill(chipBackground(color: color, isActive: isActive)))
        .contentShape(Capsule())
        .onTapGesture(perform: onTap)
    }

    private func chipBackground(color: String?, isActive: Bool) -> Color {
        if isActive {
            return colorScheme == .dark ? NookTheme.Dark.tagOn : NookTheme.Light.tagOn
        }
        if let color {
            return Color(hex: color).opacity(0.10)
        }
        return colorScheme == .dark ? NookTheme.Dark.bg2 : NookTheme.Light.bg2
    }

    private func chipForeground(isActive: Bool) -> Color {
        if isActive {
            return colorScheme == .dark ? NookTheme.Dark.tagOnFg : NookTheme.Light.tagOnFg
        }
        return NookTheme.t2(colorScheme)
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        if !name.isEmpty {
            let autoColor = Store.tagColors[store.tags.count % Store.tagColors.count]
            store.setTagColor(name, color: autoColor)
        }
        newTagName = ""
        showAddInput = false
    }

    private func displayColor(for tag: String) -> String? {
        if let color = store.tags[tag]?.color {
            return color
        }
        let scalarSum = tag.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Store.tagColors[scalarSum % Store.tagColors.count]
    }
}

private struct InlineTagColorPicker: View {
    let tag: String
    let currentColor: String?
    let colorScheme: ColorScheme
    let onSelect: (String) -> Void
    let onClose: () -> Void

    private let columns = Array(repeating: GridItem(.fixed(22), spacing: 7), count: 10)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("设置标签颜色")
                    .font(.nook(size: 11, weight: .semibold))
                    .foregroundStyle(NookTheme.t2(colorScheme))
                Text(tag)
                    .font(.nook(size: 11, weight: .medium))
                    .foregroundStyle(NookTheme.t3(colorScheme))
                Spacer()
                Button(action: onClose) {
                    NookIcon(.x, size: 9)
                        .foregroundStyle(NookTheme.t4(colorScheme))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 7) {
                ForEach(Store.tagColors, id: \.self) { color in
                    Button {
                        onSelect(color)
                    } label: {
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 22, height: 22)
                            .overlay {
                                if color == currentColor {
                                    NookIcon(.checkmark, size: 9)
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay(Circle().strokeBorder(NookTheme.line(colorScheme), lineWidth: color == currentColor ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(NookTheme.bg2(colorScheme), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Wrapping HStack (Flow Layout)

struct WrappingHStack: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (i, row) in rows.enumerated() {
            let maxH = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += maxH
            if i < rows.count - 1 { height += lineSpacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for (i, row) in rows.enumerated() {
            var x = bounds.minX
            let maxH = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y + (maxH - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
            y += maxH
            if i < rows.count - 1 { y += lineSpacing }
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxW = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentW: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentW + size.width > maxW && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentW = 0
            }
            rows[rows.count - 1].append(subview)
            currentW += size.width + spacing
        }
        return rows
    }
}

// MARK: - Color Picker Grid

struct ColorPickerGridView: View {
    let currentColor: String?
    let onSelect: (String) -> Void

    private let columns = Array(repeating: GridItem(.fixed(24), spacing: 6), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Store.tagColors, id: \.self) { color in
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 24, height: 24)
                    .overlay {
                        if color == currentColor {
                            NookIcon(.checkmark, size: 10)
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture { onSelect(color) }
            }
        }
        .padding(12)
        .frame(width: 170)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: Double
        switch h.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
