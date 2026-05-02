import SwiftUI

struct AddTaskView: View {
    @ObservedObject var store: Store
    @AppStorage("nook_filterTag") private var filterTag: String = ""
    @State private var isExpanded = false
    @State private var title = ""
    @State private var priority: NookTask.Priority = .none
    @State private var dueDate: String?
    @State private var tags: [String] = []
    @State private var showDatePicker = false
    @State private var showPriorityPicker = false
    @State private var showTagPicker = false
    @State private var tagInput = ""
    @State private var isHoveringCollapsed = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedForm
            } else {
                collapsedButton
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var collapsedButton: some View {
        Button {
            isExpanded = true
            if !filterTag.isEmpty && !tags.contains(filterTag) {
                tags.append(filterTag)
            }
        } label: {
            HStack(spacing: 6) {
                NookIcon(.plus, size: 16)
                    .foregroundStyle(NookTheme.accent(colorScheme))
                Text("添加一个待办…")
                    .font(.nook(size: 13))
                    .foregroundStyle(NookTheme.t2(colorScheme))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isHoveringCollapsed ? NookTheme.bgHover(colorScheme) : NookTheme.bg2(colorScheme), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(NookTheme.panelBorder(colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHoveringCollapsed = $0 }
    }

    private var expandedForm: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                NookIcon(.plus, size: 16)
                    .foregroundStyle(NookTheme.accent(colorScheme))
                TextField("写下待办，Enter 添加", text: $title)
                    .textFieldStyle(.plain)
                    .font(.nook(size: 14))
                    .foregroundStyle(NookTheme.t1(colorScheme))
                    .onSubmit { addTask() }
                    .onChange(of: title) { _, _ in parseInlineTags() }
                    .onExitCommand { resetForm() }
            }

            Text("Esc 取消")
                .font(.nook(size: 10))
                .foregroundStyle(NookTheme.t4(colorScheme))
                .padding(.leading, 24)

            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 2) {
                                Text("#\(tag)")
                                    .font(.nook(size: 11))
                                    .foregroundStyle(.secondary)
                                Button {
                                    tags.removeAll { $0 == tag }
                                } label: {
                                    NookIcon(.x, size: 9)
                                        .foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(tagBg(tag), in: RoundedRectangle(cornerRadius: 5))
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }

        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(NookTheme.bg(colorScheme), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(NookTheme.accent(colorScheme).opacity(0.24), lineWidth: 1)
        )
        .shadow(color: NookTheme.accent(colorScheme).opacity(0.055), radius: 9, x: 0, y: 6)
    }

    private var datePickerContent: some View {
        VStack(spacing: 2) {
            dateOption("今天", icon: .doc, color: .primary) {
                dueDate = todayString(); showDatePicker = false
            }
            dateOption("明天", icon: .calendar, color: .orange) {
                dueDate = dateString(daysFromNow: 1); showDatePicker = false
            }
            dateOption("下周", icon: .calendar, color: .blue) {
                dueDate = nextWeekString(); showDatePicker = false
            }
            Divider().padding(.horizontal, 8)
            dateOption("清除日期", icon: .x, color: .red) {
                dueDate = nil; showDatePicker = false
            }
        }
        .padding(6)
        .frame(width: 160)
    }

    private var priorityPickerContent: some View {
        VStack(spacing: 2) {
            ForEach(NookTask.Priority.allCases, id: \.self) { p in
                Button {
                    priority = p; showPriorityPicker = false
                } label: {
                    HStack(spacing: 8) {
                        NookIcon(.flag, size: 13)
                            .foregroundStyle(Color(hex: p.color))
                        Text(p.label)
                            .font(.nook(size: 13))
                        Spacer()
                        if priority == p {
                            NookIcon(.checkmark, size: 11)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .frame(width: 160)
    }

    private var tagPickerContent: some View {
        VStack(spacing: 4) {
            TextField("输入标签名", text: $tagInput)
                .textFieldStyle(.plain)
                .font(.nook(size: 12))
                .padding(6)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                .onSubmit {
                    let name = tagInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
                    if !name.isEmpty && !tags.contains(name) {
                        tags.append(name)
                    }
                    tagInput = ""
                }

            let allTagNames = Array(store.tags.keys).sorted()
            ForEach(allTagNames, id: \.self) { tag in
                Button {
                    if tags.contains(tag) {
                        tags.removeAll { $0 == tag }
                    } else {
                        tags.append(tag)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: store.tags[tag]?.color ?? "#999"))
                            .frame(width: 8, height: 8)
                        Text("#\(tag)")
                            .font(.nook(size: 12))
                        Spacer()
                        if tags.contains(tag) {
                            NookIcon(.checkmark, size: 10)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(width: 180)
        .frame(maxHeight: 250)
    }

    private func toolbarButton(icon: NookIconName, isActive: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            NookIcon(icon, size: 13)
                .foregroundStyle(isActive ? color : .secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func dateOption(_ label: String, icon: NookIconName, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                NookIcon(icon, size: 13)
                    .foregroundStyle(color)
                    .frame(width: 18)
                Text(label)
                    .font(.nook(size: 13))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func addTask() {
        let raw = title.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }
        let cleanTitle = raw.replacingOccurrences(of: "#[\\w\\u4e00-\\u9fff]+", with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces)
        guard !cleanTitle.isEmpty else { return }
        let uniqueTags = Array(Set(tags))
        for tag in uniqueTags where store.tags[tag]?.color == nil {
            let autoColor = Store.tagColors[store.tags.count % Store.tagColors.count]
            store.setTagColor(tag, color: autoColor)
        }
        store.addTask(title: cleanTitle, priority: priority, tags: uniqueTags, dueDate: dueDate)
        resetForm()
    }

    private func resetForm() {
        title = ""
        priority = .none
        dueDate = nil
        tags = []
        tagInput = ""
        isExpanded = false
        showDatePicker = false
        showPriorityPicker = false
        showTagPicker = false
    }

    private func parseInlineTags() {
        let pattern = "#([\\w\\u{4e00}-\\u{9fff}]+)\\s"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let nsTitle = title as NSString
        let matches = regex.matches(in: title, range: NSRange(location: 0, length: nsTitle.length))
        for match in matches.reversed() {
            let tag = nsTitle.substring(with: match.range(at: 1))
            if !tags.contains(tag) { tags.append(tag) }
            title = nsTitle.replacingCharacters(in: match.range, with: "")
        }
    }

    private func tagBg(_ tag: String) -> Color {
        if let hex = store.tags[tag]?.color {
            return Color(hex: hex).opacity(0.2)
        }
        return NookTheme.bg2(colorScheme)
    }

    private func todayString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func dateString(daysFromNow: Int) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())!)
    }

    private func nextWeekString() -> String {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date())
        let daysUntilMonday = (9 - weekday) % 7
        let days = daysUntilMonday == 0 ? 7 : daysUntilMonday
        return dateString(daysFromNow: days)
    }
}
