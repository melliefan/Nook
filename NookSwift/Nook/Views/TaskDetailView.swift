import SwiftUI

struct TaskDetailView: View {
    @ObservedObject var store: Store
    let taskId: Int?
    let onBack: () -> Void

    @State private var editTitle = ""
    @State private var editDesc = ""
    @State private var selectedPriority: NookTask.Priority = .none
    @State private var selectedTags: [String] = []
    @State private var selectedDueDate: String?
    @State private var newSubtaskTitle = ""
    @State private var draftSubtasks: [Subtask] = []
    @State private var showDatePicker = false
    @State private var showPriorityPicker = false
    @State private var showTagSheet = false
    @State private var pickerMonth = Date()
    @FocusState private var titleFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var task: NookTask? {
        guard let taskId else { return nil }
        return store.tasks.first { $0.id == taskId }
    }

    private var isNew: Bool { taskId == nil }

    var body: some View {
        VStack(spacing: 0) {
            detailHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    editorFields
                    metaSection
                    tagSection
                    subtaskSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(NookTheme.bg(colorScheme))
        .overlay {
            if showTagSheet {
                Color(hex: "#1E1E2A")
                    .opacity(colorScheme == .dark ? 0.22 : 0.08)
                    .ignoresSafeArea()
                    .onTapGesture { showTagSheet = false }
                TagSelectorOverlay(
                    store: store,
                    selectedTags: $selectedTags,
                    isPresented: $showTagSheet,
                    colorScheme: colorScheme
                )
            }
        }
        .onAppear(perform: loadState)
    }

    private var detailHeader: some View {
        HStack(spacing: 0) {
            Button { saveAndBack() } label: {
                NookIcon(.arrow, size: 14)
                    .rotationEffect(.degrees(180))
                    .foregroundStyle(NookTheme.t1(colorScheme))
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(width: 36, alignment: .leading)

            Text(isNew ? "新增任务" : "编辑任务")
                .font(.nook(size: 12, weight: .semibold))
                .foregroundStyle(NookTheme.t1(colorScheme))
                .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                // 导出 .ics — only meaningful if a due date exists
                if selectedDueDate != nil, let editingTask = task {
                    Button {
                        _ = ICSExporter.exportAndOpen(tasks: [editingTask])
                    } label: {
                        NookIcon(.copy, size: 12)
                            .foregroundStyle(NookTheme.t3(colorScheme))
                    }
                    .buttonStyle(.plain)
                    .help("导出此任务到日历 (.ics)")
                }
                Button("保存") { saveAndBack() }
                    .font(.nook(size: 12, weight: .semibold))
                    .foregroundStyle(NookTheme.accent(colorScheme))
                    .buttonStyle(.plain)
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 18)
    }

    private var editorFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("写下待办", text: $editTitle, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.nook(size: 18, weight: .semibold))
                .foregroundStyle(NookTheme.t1(colorScheme))
                .lineLimit(1...3)
                .focused($titleFocused)
                .onSubmit { saveChanges() }

            TextField("备注，可不填", text: $editDesc, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.nook(size: 12))
                .foregroundStyle(NookTheme.t3(colorScheme))
                .lineLimit(2...7)
        }
        .padding(.bottom, 15)
    }

    private var metaSection: some View {
        HStack(spacing: 10) {
            Button {
                showDatePicker.toggle()
                showPriorityPicker = false
            } label: {
                HStack(spacing: 5) {
                    NookIcon(.calendar, size: 13)
                    Text(formattedDueDate)
                        .font(.system(size: 11, weight: selectedDueDate == nil ? .medium : .semibold))
                }
                .foregroundStyle(selectedDueDate == nil ? NookTheme.t4(colorScheme) : NookTheme.accent(colorScheme))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                CompactCalendarPicker(
                    selectedDueDate: $selectedDueDate,
                    pickerMonth: $pickerMonth,
                    isPresented: $showDatePicker,
                    colorScheme: colorScheme
                )
            }

            Text("·")
                .font(.nook(size: 12, weight: .bold))
                .foregroundStyle(NookTheme.t4(colorScheme))

            Button {
                showPriorityPicker.toggle()
                showDatePicker = false
            } label: {
                HStack(spacing: 5) {
                    NookIcon(.flag, size: 13)
                    Text(selectedPriority.label)
                        .font(.nook(size: 11, weight: .semibold))
                }
                .foregroundStyle(Color(hex: selectedPriority.color))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPriorityPicker, arrowEdge: .bottom) {
                CompactPriorityPicker(
                    selectedPriority: $selectedPriority,
                    isPresented: $showPriorityPicker,
                    colorScheme: colorScheme
                )
            }

            Spacer()
        }
        .padding(.bottom, 15)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(NookTheme.line(colorScheme).opacity(0.7))
                .frame(height: 1)
        }
        .padding(.bottom, 15)
    }

    private var tagSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("标签")
                .font(.nook(size: 12, weight: .medium))
                .foregroundStyle(NookTheme.t3(colorScheme))
                .frame(width: 42, alignment: .leading)
                .padding(.top, 5)

            WrappingHStack(spacing: 7, lineSpacing: 6) {
                ForEach(selectedTags, id: \.self) { tag in
                    tagChip(tag)
                }
                Button {
                    showTagSheet = true
                } label: {
                    HStack(spacing: 4) {
                        NookIcon(.plus, size: 12)
                        Text("添加")
                            .font(.nook(size: 11, weight: .medium))
                    }
                    .foregroundStyle(NookTheme.t4(colorScheme))
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(NookTheme.accent(colorScheme).opacity(0.32), style: StrokeStyle(lineWidth: 1.3, dash: [4, 4]))
                    )
                    .background(NookTheme.blueBg(colorScheme).opacity(0.35), in: RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(NookTheme.line(colorScheme).opacity(0.7))
                .frame(height: 1)
        }
        .padding(.bottom, 15)
    }

    private var subtaskSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                NookIcon(.check, size: 15)
                    .foregroundStyle(NookTheme.t3(colorScheme))
                Text("子任务")
                    .font(.nook(size: 12, weight: .medium))
                    .foregroundStyle(NookTheme.t3(colorScheme))
                let count = displayedSubtasks.count
                if count > 0 {
                    Text("\(completedSubtaskCount)/\(count)")
                        .font(.nook(size: 11))
                        .foregroundStyle(NookTheme.t4(colorScheme))
                }
                Spacer()
            }
            .padding(.bottom, 8)

            ForEach(displayedSubtasks) { subtask in
                subtaskRow(subtask)
            }

            HStack(spacing: 6) {
                NookIcon(.plus, size: 12)
                TextField("添加子任务", text: $newSubtaskTitle)
                    .textFieldStyle(.plain)
                    .font(.nook(size: 12))
                    .onSubmit { addSubtask() }
            }
            .foregroundStyle(NookTheme.t4(colorScheme))
            .padding(.leading, 23)
            .padding(.top, 6)
        }
    }

    private var displayedSubtasks: [Subtask] {
        task?.subtasks ?? draftSubtasks
    }

    private var completedSubtaskCount: Int {
        displayedSubtasks.filter(\.completed).count
    }

    private var formattedDueDate: String {
        guard let selectedDueDate else { return "选择日期" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: selectedDueDate) else { return "选择日期" }
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func tagChip(_ tag: String) -> some View {
        let color = displayColor(for: tag)
        return HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 6, height: 6)
            Text(tag)
                .font(.nook(size: 11, weight: .medium))
            Button {
                selectedTags.removeAll { $0 == tag }
            } label: {
                NookIcon(.x, size: 7)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(NookTheme.t2(colorScheme))
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(Color(hex: color).opacity(0.10), in: Capsule())
    }

    private func subtaskRow(_ subtask: Subtask) -> some View {
        HStack(spacing: 8) {
            Button {
                toggleSubtask(subtask.id)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(subtask.completed ? NookTheme.accent(colorScheme) : NookTheme.t4(colorScheme), lineWidth: 1.4)
                        .frame(width: 14, height: 14)
                    if subtask.completed {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(NookTheme.accent(colorScheme))
                            .frame(width: 14, height: 14)
                        NookIcon(.checkmark, size: 7)
                            .foregroundStyle(NookTheme.tagOnFg(colorScheme))
                    }
                }
            }
            .buttonStyle(.plain)

            Text(subtask.title)
                .font(.nook(size: 12))
                .foregroundStyle(subtask.completed ? NookTheme.t4(colorScheme) : NookTheme.t2(colorScheme))
                .strikethrough(subtask.completed)

            Spacer()

            Button {
                deleteSubtask(subtask.id)
            } label: {
                NookIcon(.x, size: 8)
                    .foregroundStyle(NookTheme.t4(colorScheme))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 23)
        .padding(.vertical, 5)
    }

    private func loadState() {
        if let task {
            editTitle = task.title
            editDesc = task.description
            selectedPriority = task.priority
            selectedTags = task.tags
            selectedDueDate = task.dueDate
            draftSubtasks = []
        } else {
            titleFocused = true
        }
    }

    private func saveChanges() {
        let title = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        if let taskId {
            store.updateTask(taskId, title: title, description: editDesc, priority: selectedPriority, tags: selectedTags, dueDate: .some(selectedDueDate))
        } else {
            let newId = store.addTask(title: title, description: editDesc, priority: selectedPriority, tags: selectedTags, dueDate: selectedDueDate)
            for subtask in draftSubtasks {
                store.addSubtask(newId, title: subtask.title)
                if subtask.completed {
                    store.toggleSubtask(newId, subId: subtask.id)
                }
            }
        }
    }

    private func saveAndBack() {
        saveChanges()
        onBack()
    }

    private func addSubtask() {
        let title = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        if let taskId {
            store.addSubtask(taskId, title: title)
        } else {
            let nextId = (draftSubtasks.map(\.id).max() ?? 0) + 1
            draftSubtasks.append(Subtask(id: nextId, title: title, completed: false))
        }
        newSubtaskTitle = ""
    }

    private func toggleSubtask(_ id: Int) {
        if let taskId {
            store.toggleSubtask(taskId, subId: id)
        } else if let index = draftSubtasks.firstIndex(where: { $0.id == id }) {
            draftSubtasks[index].completed.toggle()
        }
    }

    private func deleteSubtask(_ id: Int) {
        if let taskId {
            store.deleteSubtask(taskId, subId: id)
        } else {
            draftSubtasks.removeAll { $0.id == id }
        }
    }

    private func displayColor(for tag: String) -> String {
        if let color = store.tags[tag]?.color { return color }
        let scalarSum = tag.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Store.tagColors[scalarSum % Store.tagColors.count]
    }
}

private struct CompactCalendarPicker: View {
    @Binding var selectedDueDate: String?
    @Binding var pickerMonth: Date
    @Binding var isPresented: Bool
    let colorScheme: ColorScheme

    private let calendar = Calendar.current
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button { moveMonth(-1) } label: {
                    NookIcon(.arrow, size: 10)
                        .rotationEffect(.degrees(180))
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .background(NookTheme.bg2(colorScheme), in: RoundedRectangle(cornerRadius: 8))

                Spacer()

                Text(monthTitle)
                    .font(.nook(size: 12, weight: .bold))
                    .foregroundStyle(NookTheme.t1(colorScheme))

                Spacer()

                Button { moveMonth(1) } label: {
                    NookIcon(.arrow, size: 10)
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 22)
                .background(NookTheme.bg2(colorScheme), in: RoundedRectangle(cornerRadius: 8))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.nook(size: 9, weight: .semibold))
                        .foregroundStyle(NookTheme.t4(colorScheme))
                        .frame(height: 14)
                }

                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        Button { select(date) } label: {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 11, weight: isSelected(date) ? .bold : .medium))
                                .foregroundStyle(isSelected(date) ? .white : NookTheme.t2(colorScheme))
                                .frame(maxWidth: .infinity)
                                .frame(height: 25)
                                .background(isSelected(date) ? NookTheme.accent(colorScheme) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(isToday(date) && !isSelected(date) ? NookTheme.accent(colorScheme).opacity(0.22) : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 25)
                    }
                }
            }

            HStack {
                Button("清除日期") {
                    selectedDueDate = nil
                    isPresented = false
                }
                .font(.nook(size: 11, weight: .medium))
                .foregroundStyle(NookTheme.t4(colorScheme))
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(width: 236)
        .onAppear {
            if let selectedDueDate, let date = parse(selectedDueDate) {
                pickerMonth = date
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: pickerMonth)
    }

    private var monthDays: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: pickerMonth),
              let days = calendar.range(of: .day, in: .month, for: pickerMonth) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let prefix = Array<Date?>(repeating: nil, count: firstWeekday - 1)
        let dates = days.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }
        return prefix + dates
    }

    private func moveMonth(_ value: Int) {
        pickerMonth = calendar.date(byAdding: .month, value: value, to: pickerMonth) ?? pickerMonth
    }

    private func select(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        selectedDueDate = formatter.string(from: date)
        // Brief delay so user sees the selection highlight before popover dismisses
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            isPresented = false
        }
    }

    private func parse(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedDueDate, let selected = parse(selectedDueDate) else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
}

private struct CompactPriorityPicker: View {
    @Binding var selectedPriority: NookTask.Priority
    @Binding var isPresented: Bool
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(NookTask.Priority.allCases, id: \.self) { priority in
                Button {
                    selectedPriority = priority
                    // Brief delay so the selected flag's highlight is visible before close
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        isPresented = false
                    }
                } label: {
                    NookIcon(.flag, size: 13)
                        .foregroundStyle(Color(hex: priority.color).opacity(priority == selectedPriority ? 1 : 0.55))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(priority.label)
            }
        }
        .padding(8)
        // Override the macOS popover's translucent menu material with the panel's
        // solid bg so flags don't pick up the gray haze behind them.
        .background(NookTheme.bg(colorScheme))
    }
}

private struct TagSelectorOverlay: View {
    @ObservedObject var store: Store
    @Binding var selectedTags: [String]
    @Binding var isPresented: Bool
    let colorScheme: ColorScheme
    @State private var searchText = ""
    @State private var pendingColor: String?
    @State private var showColorPicker = false
    @State private var editingColorTag: String?
    @State private var hoveredRowTag: String?

    /// 8-color picker palette — first 8 of Store.tagColors, distinct enough at a glance.
    private static let pickerColors: [String] = [
        "#FF6B6B", "#FF8A65", "#FFB74D", "#FFD54F",
        "#81C784", "#4FC3F7", "#7986CB", "#BA68C8",
    ]

    private var allTags: [String] {
        Array(Set(store.tags.keys).union(store.tasks.flatMap(\.tags))).sorted()
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
    }

    private var filteredTags: [String] {
        let q = trimmedQuery.lowercased()
        guard !q.isEmpty else { return allTags }
        return allTags.filter { $0.lowercased().contains(q) }
    }

    /// Show the "+ 创建" row only when query is non-empty AND no existing tag matches exactly.
    private var canCreate: Bool {
        let q = trimmedQuery
        guard !q.isEmpty else { return false }
        return !allTags.contains { $0.caseInsensitiveCompare(q) == .orderedSame }
    }

    /// Auto-color for new tag: first palette color not yet used by any tag.
    /// If all 8 are taken, fall back to count-based rotation.
    private var autoColor: String {
        let used = Set(store.tags.values.map(\.color))
        if let unused = Self.pickerColors.first(where: { !used.contains($0) }) {
            return unused
        }
        return Self.pickerColors[store.tags.count % Self.pickerColors.count]
    }

    private var effectiveCreateColor: String { pendingColor ?? autoColor }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("添加标签")
                    .font(.nook(size: 13, weight: .semibold))
                    .foregroundStyle(NookTheme.t1(colorScheme))
                Spacer()
                Button { isPresented = false } label: {
                    NookIcon(.x, size: 11)
                        .foregroundStyle(NookTheme.t3(colorScheme))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 40)

            // Search / create input — soft fill, no border, no dividers around it
            HStack(spacing: 7) {
                NookIcon(.tag, size: 12)
                    .foregroundStyle(NookTheme.t4(colorScheme))
                TextField("搜索或输入新标签", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.nook(size: 12))
                    .onSubmit { commitCreateIfNeeded() }
                    .onChange(of: searchText) { _, _ in
                        if pendingColor == nil { showColorPicker = false }
                    }
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(NookTheme.bg2(colorScheme).opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)

            // List — scroll indicators hidden for minimal look; trackpad scroll still works
            ScrollView {
                VStack(spacing: 1) {
                    if canCreate {
                        createRow
                    }
                    ForEach(filteredTags, id: \.self) { tag in
                        existingTagRow(tag)
                    }
                }
                .padding(4)
            }
            .scrollIndicators(.never)
            .frame(maxHeight: 252)
            .padding(.horizontal, 8)
            .padding(.top, 8)

            // Footer — no top divider, just generous spacing
            HStack {
                Text(selectedTags.isEmpty ? "回车创建" : "\(selectedTags.count) 个已选")
                    .font(.nook(size: 10))
                    .foregroundStyle(NookTheme.t4(colorScheme))
                Spacer()
                Button { isPresented = false } label: {
                    Text("取消")
                        .font(.nook(size: 12, weight: .medium))
                        .foregroundStyle(NookTheme.t1(colorScheme))
                        .padding(.horizontal, 14)
                        .frame(height: 28)
                        .background(NookTheme.bg(colorScheme), in: RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(NookTheme.line(colorScheme), lineWidth: 1))
                }
                .buttonStyle(.plain)
                Button {
                    commitCreateIfNeeded()
                    isPresented = false
                } label: {
                    Text("完成")
                        .font(.nook(size: 12, weight: .semibold))
                        .foregroundStyle(NookTheme.tagOnFg(colorScheme))
                        .padding(.horizontal, 14)
                        .frame(height: 28)
                        .background(NookTheme.accent(colorScheme), in: RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 300)
        .background(NookTheme.bg(colorScheme), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(NookTheme.line(colorScheme), lineWidth: 1))
        .shadow(color: Color(hex: "#1E1E2A").opacity(colorScheme == .dark ? 0.34 : 0.14), radius: 26, x: 0, y: 16)
    }

    // MARK: - Rows

    private var createRow: some View {
        VStack(spacing: 6) {
            Button {
                commitCreateIfNeeded()
            } label: {
                HStack(spacing: 8) {
                    NookIcon(.plus, size: 12)
                        .foregroundStyle(NookTheme.accent(colorScheme))
                        .frame(width: 14)
                    HStack(spacing: 4) {
                        Text("创建")
                            .font(.nook(size: 12, weight: .medium))
                            .foregroundStyle(NookTheme.accent(colorScheme))
                        Text("\"\(trimmedQuery)\"")
                            .font(.nook(size: 12, weight: .semibold))
                            .foregroundStyle(NookTheme.t1(colorScheme))
                            .lineLimit(1)
                    }
                    Spacer()
                    Button {
                        showColorPicker.toggle()
                    } label: {
                        Circle()
                            .fill(Color(hex: effectiveCreateColor))
                            .frame(width: 10, height: 10)
                    }
                    .buttonStyle(.plain)
                    .help("点击换色")
                }
                .padding(.horizontal, 10)
                .frame(height: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showColorPicker {
                HStack(spacing: 6) {
                    ForEach(Self.pickerColors, id: \.self) { color in
                        Button {
                            pendingColor = color
                        } label: {
                            ZStack {
                                Circle().fill(Color(hex: color)).frame(width: 16, height: 16)
                                if effectiveCreateColor == color {
                                    NookIcon(.checkmark, size: 8)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 32)
                .padding(.bottom, 4)
            }
        }
        .background(NookTheme.bgHover(colorScheme).opacity(showColorPicker ? 0.5 : 0), in: RoundedRectangle(cornerRadius: 7))
    }

    @ViewBuilder
    private func existingTagRow(_ tag: String) -> some View {
        let color = displayColor(for: tag)
        let isSelected = selectedTags.contains(tag)
        let isEditing = editingColorTag == tag

        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Color dot — clickable to open color editor (independent of select)
                Button {
                    editingColorTag = isEditing ? nil : tag
                } label: {
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 11, height: 11)
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("点击改色")

                // Name + count zone — clickable to select/deselect
                HStack(spacing: 6) {
                    Text(tag)
                        .font(.nook(size: 12, weight: .medium))
                        .foregroundStyle(NookTheme.t1(colorScheme))
                        .lineLimit(1)
                    Spacer()
                    // 18pt 固定槽：count + × 用 ZStack 共占同一空间，opacity 切换
                    let count = store.tasks.filter { $0.tags.contains(tag) }.count
                    ZStack(alignment: .trailing) {
                        Text(count > 0 ? "\(count)" : "")
                            .font(.nook(size: 10, weight: .medium))
                            .foregroundStyle(NookTheme.t4(colorScheme))
                            .opacity(hoveredRowTag == tag && !isEditing ? 0 : 1)
                        Button {
                            hoveredRowTag = nil
                            store.deleteTag(tag)
                            selectedTags.removeAll { $0 == tag }
                        } label: {
                            NookIcon(.x, size: 9)
                                .foregroundStyle(NookTheme.t3(colorScheme))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .opacity(hoveredRowTag == tag && !isEditing ? 1 : 0)
                        .allowsHitTesting(hoveredRowTag == tag && !isEditing)
                        .help("删除标签")
                    }
                    .frame(width: 18, alignment: .trailing)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isSelected {
                        selectedTags.removeAll { $0 == tag }
                    } else {
                        selectedTags.append(tag)
                    }
                }

                // Right-side affordance: delete (when editing) OR filled-circle ✓ (selected)
                if isEditing {
                    Button {
                        store.deleteTag(tag)
                        selectedTags.removeAll { $0 == tag }
                        editingColorTag = nil
                    } label: {
                        NookIcon(.trash, size: 11)
                            .foregroundStyle(NookTheme.t3(colorScheme))
                            .frame(width: 18, height: 18)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("删除标签")
                } else if isSelected {
                    Circle()
                        .fill(NookTheme.accent(colorScheme))
                        .frame(width: 13, height: 13)
                        .overlay(
                            NookIcon(.checkmark, size: 7)
                                .foregroundStyle(NookTheme.tagOnFg(colorScheme))
                        )
                } else {
                    Color.clear.frame(width: 13, height: 13)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .onHover { hovering in
                if hovering { hoveredRowTag = tag }
                else if hoveredRowTag == tag { hoveredRowTag = nil }
            }

            if isEditing {
                HStack(spacing: 6) {
                    ForEach(Self.pickerColors, id: \.self) { c in
                        Button {
                            store.setTagColor(tag, color: c)
                            editingColorTag = nil
                        } label: {
                            ZStack {
                                Circle().fill(Color(hex: c)).frame(width: 16, height: 16)
                                if color == c {
                                    NookIcon(.checkmark, size: 8).foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 32)
                .padding(.trailing, 10)
                .padding(.bottom, 6)
            }
        }
        .background(
            isEditing
                ? NookTheme.bg2(colorScheme).opacity(0.85)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 7)
        )
    }

    // MARK: - Actions

    private func commitCreateIfNeeded() {
        let name = trimmedQuery
        guard !name.isEmpty else { return }
        if !allTags.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            store.setTagColor(name, color: effectiveCreateColor)
        }
        if !selectedTags.contains(name) {
            selectedTags.append(name)
        }
        searchText = ""
        pendingColor = nil
        showColorPicker = false
    }

    private func displayColor(for tag: String) -> String {
        if let color = store.tags[tag]?.color { return color }
        let scalarSum = tag.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Store.tagColors[scalarSum % Store.tagColors.count]
    }
}
