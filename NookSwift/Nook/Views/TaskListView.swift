import SwiftUI

struct TaskListView: View {
    @ObservedObject var store: Store
    let onDetail: (Int) -> Void
    @AppStorage("nook_sort") private var currentSort = "custom"
    @AppStorage("nook_filterTag") private var filterTag: String = ""
    @State private var completedCollapsed = true
    @State private var draggingTaskId: Int?
    @State private var dropTargetTaskId: Int?
    @Environment(\.colorScheme) private var colorScheme

    private var activeTasks: [NookTask] {
        var list = store.tasks.filter { !$0.completed }
        if !filterTag.isEmpty {
            list = list.filter { $0.tags.contains(filterTag) }
        }
        return sortTasks(list)
    }

    private var completedTasks: [NookTask] {
        var list = store.tasks.filter(\.completed)
        if !filterTag.isEmpty {
            list = list.filter { $0.tags.contains(filterTag) }
        }
        return list
    }

    private var canReorder: Bool {
        currentSort == "custom" && filterTag.isEmpty
    }

    var body: some View {
        // When there's nothing at all, show a centered empty state instead of
        // a top-anchored ScrollView item — fills available height and centers.
        if activeTasks.isEmpty && completedTasks.isEmpty {
            emptyState
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(activeTasks) { task in
                        TaskRowView(
                            task: task,
                            store: store,
                            onDetail: onDetail,
                            isReorderEnabled: canReorder,
                            draggingTaskId: $draggingTaskId,
                            isDropTarget: dropTargetTaskId == task.id && draggingTaskId != task.id
                        )
                        .onDrop(of: ["public.text"], isTargeted: Binding(
                            get: { dropTargetTaskId == task.id },
                            set: { hovered in
                                if hovered {
                                    dropTargetTaskId = task.id
                                } else if dropTargetTaskId == task.id {
                                    dropTargetTaskId = nil
                                }
                            }
                        )) { _ in
                            guard canReorder,
                                  let sourceId = draggingTaskId,
                                  sourceId != task.id,
                                  let targetIndex = store.tasks.firstIndex(where: { $0.id == task.id }) else {
                                draggingTaskId = nil
                                dropTargetTaskId = nil
                                return false
                            }
                            withAnimation(.easeInOut(duration: 0.18)) {
                                store.reorderTask(sourceId, to: targetIndex)
                            }
                            draggingTaskId = nil
                            dropTargetTaskId = nil
                            return true
                        }
                    }

                    if !completedTasks.isEmpty {
                        completedSection
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.never)
            .frame(maxHeight: .infinity)
        }
    }

    private var completedSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    completedCollapsed.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    NookIcon(.chevron, size: 10)
                        .rotationEffect(.degrees(completedCollapsed ? 0 : 90))
                        .foregroundStyle(NookTheme.t4(colorScheme))
                    Text("已完成")
                        .font(.nook(size: 11, weight: .semibold))
                        .foregroundStyle(NookTheme.t3(colorScheme))
                    Text("\(completedTasks.count)")
                        .font(.nook(size: 11))
                        .foregroundStyle(NookTheme.t4(colorScheme))
                    Spacer()
                    Button {
                        store.clearCompleted()
                    } label: {
                        NookIcon(.trash, size: 11)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !completedCollapsed {
                ForEach(completedTasks) { task in
                    TaskRowView(
                        task: task,
                        store: store,
                        onDetail: onDetail,
                        isReorderEnabled: false,
                        draggingTaskId: .constant(nil)
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            if let url = Bundle.main.url(forResource: "empty-state", withExtension: "png"),
               let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300)
            } else {
                NookIcon(.inbox, size: 56)
                    .foregroundStyle(.quaternary)
            }
            VStack(spacing: 4) {
                Text("收件箱空空如也")
                    .font(.nook(size: 14, weight: .medium))
                    .foregroundStyle(NookTheme.t2(colorScheme))
                Text("点右上角 + 添加待办，或让 Claude 帮你记一笔")
                    .font(.nook(size: 11))
                    .foregroundStyle(NookTheme.t4(colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func sortTasks(_ list: [NookTask]) -> [NookTask] {
        switch currentSort {
        case "priority":
            return list.sorted { $0.priority.order < $1.priority.order }
        case "dueDate":
            return list.sorted {
                guard let a = $0.dueDate else { return false }
                guard let b = $1.dueDate else { return true }
                return a < b
            }
        case "title":
            return list.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case "created":
            return list.sorted { $0.createdAt > $1.createdAt }
        default:
            return list
        }
    }
}

// MARK: - Task Row

struct TaskRowView: View {
    let task: NookTask
    @ObservedObject var store: Store
    let onDetail: (Int) -> Void
    let isReorderEnabled: Bool
    @Binding var draggingTaskId: Int?
    var isDropTarget: Bool = false
    @State private var isHovering = false
    @State private var showSubtasks = false
    @State private var newSubtaskTitle = ""
    @State private var isAddingSubtask = false
    @Environment(\.colorScheme) private var colorScheme

    private var isBeingDragged: Bool { draggingTaskId == task.id }

    private var checkboxColor: Color {
        // Uniform dark-gray accent for every checkbox — priority and tag colors
        // are already shown in the meta row, so painting the box too made it noisy.
        if task.completed {
            return NookTheme.accent(colorScheme)
        }
        return NookTheme.t4(colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Insertion-line indicator above target row when something's being dragged onto it
            Rectangle()
                .fill(NookTheme.accent(colorScheme))
                .frame(height: isDropTarget ? 2 : 0)
                .padding(.horizontal, 8)
                .opacity(isDropTarget ? 1 : 0)
                .animation(.easeInOut(duration: 0.12), value: isDropTarget)

            mainRow
            if showSubtasks && !task.completed {
                subtaskSection
            }
        }
        .opacity(isBeingDragged ? 0.35 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isBeingDragged)
    }

    private var mainRow: some View {
        HStack(spacing: 10) {
            checkbox

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.nook(size: 14, weight: .regular))
                    .foregroundStyle(task.completed ? NookTheme.t4(colorScheme) : NookTheme.t1(colorScheme))
                    .strikethrough(task.completed)
                    .lineLimit(2)
                    .lineSpacing(1)

                if !task.completed, let desc = task.description.split(separator: "\n").first, !desc.isEmpty {
                    Text(desc)
                        .font(.nook(size: 12))
                        .foregroundStyle(NookTheme.t3(colorScheme))
                        .lineLimit(1)
                }

                metaRow
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !task.completed {
                    withAnimation(.easeInOut(duration: 0.15)) { showSubtasks.toggle() }
                }
            }

            Spacer(minLength: 4)

            // Action icons always occupy layout space — only opacity/hit-testing flip on hover.
            // Otherwise the row reflows when icons appear, causing tag chips to wrap mid-text.
            HStack(spacing: 3) {
                if isReorderEnabled {
                    NookIcon(.drag, size: 13)
                        .foregroundStyle(NookTheme.t3(colorScheme))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                        .onDrag {
                            draggingTaskId = task.id
                            return NSItemProvider(object: "\(task.id)" as NSString)
                        }
                        .help("拖拽排序")
                }
                Button { onDetail(task.id) } label: {
                    NookIcon(.pen, size: 12)
                        .foregroundStyle(NookTheme.t3(colorScheme))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { store.deleteTask(task.id) }
                } label: {
                    NookIcon(.trash, size: 12)
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .opacity(isHovering ? 1 : 0)
            .allowsHitTesting(isHovering)
        }
        .padding(.horizontal, isHovering ? 12 : 16)
        .padding(.vertical, 10)
        .background(isHovering ? NookTheme.bgHover(colorScheme) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, isHovering ? 4 : 0)
        .shadow(
            color: isHovering ? (colorScheme == .dark ? Color.black.opacity(0.14) : Color(hex: "#1E1E2A").opacity(0.04)) : Color.clear,
            radius: 3,
            x: 0,
            y: 1
        )
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("查看详情") { onDetail(task.id) }
            Menu("优先级") {
                ForEach(NookTask.Priority.allCases, id: \.self) { p in
                    Button(p.label) { store.updateTask(task.id, priority: p) }
                }
            }
            Divider()
            Button("删除", role: .destructive) { store.deleteTask(task.id) }
        }
    }

    private var checkbox: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                store.toggleTask(task.id)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(checkboxColor, lineWidth: 2)
                    .frame(width: 18, height: 18)
                if task.completed {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(checkboxColor)
                        .frame(width: 18, height: 18)
                    NookIcon(.checkmark, size: 9)
                        .foregroundStyle(NookTheme.tagOnFg(colorScheme))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 26, height: 26)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var metaRow: some View {
        let hasDate = task.formattedDueDate != nil
        let hasTags = !task.tags.isEmpty
        let hasSubs = !task.subtasks.isEmpty

        if hasDate || hasTags || hasSubs {
            // Flow layout — meta items stay full-size, wrap to a new line when row width
            // is exceeded. Better than `…` truncation when many tags share the row.
            WrappingHStack(spacing: 8, lineSpacing: 4) {
                if let dateStr = task.formattedDueDate {
                    HStack(spacing: 3) {
                        NookIcon(.calendar, size: 11)
                        Text(dateStr)
                            .font(.nook(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(task.isOverdue ? (colorScheme == .dark ? NookTheme.redDark : NookTheme.red) : NookTheme.accent(colorScheme))
                }

                ForEach(task.tags, id: \.self) { tag in
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color(hex: displayColor(for: tag) ?? "#999"))
                            .frame(width: 5, height: 5)
                        Text(tag)
                            .font(.nook(size: 10, weight: .medium))
                            .foregroundStyle(NookTheme.t2(colorScheme))
                            .lineLimit(1)
                    }
                }

                if hasSubs {
                    let done = task.subtasks.filter(\.completed).count
                    Text("子任务 \(done)/\(task.subtasks.count)")
                        .font(.nook(size: 10, weight: .medium))
                        .foregroundStyle(NookTheme.t3(colorScheme))
                        .lineLimit(1)
                }
            }
            .padding(.top, 5)
        }
    }

    // MARK: - Inline Subtasks

    private var subtaskSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(task.subtasks) { sub in
                HStack(spacing: 7) {
                    Button {
                        store.toggleSubtask(task.id, subId: sub.id)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(sub.completed ? NookTheme.accent(colorScheme) : NookTheme.t4(colorScheme), lineWidth: 1.5)
                                .frame(width: 13, height: 13)
                            if sub.completed {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(NookTheme.accent(colorScheme))
                                    .frame(width: 13, height: 13)
                                NookIcon(.checkmark, size: 6)
                                    .foregroundStyle(NookTheme.tagOnFg(colorScheme))
                            }
                        }
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Text(sub.title)
                        .font(.nook(size: 12))
                        .foregroundStyle(sub.completed ? NookTheme.t4(colorScheme) : NookTheme.t1(colorScheme))
                        .strikethrough(sub.completed)

                    Spacer()

                    if isHovering {
                        Button {
                            store.deleteSubtask(task.id, subId: sub.id)
                        } label: {
                            NookIcon(.x, size: 8)
                                .foregroundStyle(NookTheme.t4(colorScheme))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if isAddingSubtask {
                HStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(NookTheme.t4(colorScheme), lineWidth: 1.5)
                        .frame(width: 13, height: 13)
                    TextField("输入子任务", text: $newSubtaskTitle)
                        .textFieldStyle(.plain)
                        .font(.nook(size: 12))
                        .onSubmit {
                            let t = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
                            if !t.isEmpty { store.addSubtask(task.id, title: t) }
                            newSubtaskTitle = ""
                            isAddingSubtask = false
                        }
                        .onExitCommand { newSubtaskTitle = ""; isAddingSubtask = false }
                }
            } else {
                Button { isAddingSubtask = true } label: {
                    HStack(spacing: 4) {
                        NookIcon(.plus, size: 10)
                        Text("添加子任务")
                            .font(.nook(size: 11))
                    }
                    .foregroundStyle(NookTheme.t3(colorScheme))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 44)
        .padding(.trailing, 10)
        .padding(.top, 2)
        .padding(.bottom, 6)
    }

    private func displayColor(for tag: String) -> String? {
        if let color = store.tags[tag]?.color {
            return color
        }
        let scalarSum = tag.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Store.tagColors[scalarSum % Store.tagColors.count]
    }
}
