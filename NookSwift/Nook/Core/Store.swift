import Foundation
import SwiftUI

struct TagInfo: Codable, Equatable {
    var color: String?
}

struct StoreData: Codable {
    var tasks: [NookTask]
    var nextId: Int
    var tags: [String: TagInfo]
    var snippets: [Snippet]
    var nextSnippetId: Int
    var settings: NookSettings

    init() {
        tasks = []
        nextId = 1
        tags = [:]
        snippets = []
        nextSnippetId = 1
        settings = NookSettings()
    }
}

@MainActor
final class Store: ObservableObject {
    @Published var tasks: [NookTask] = []
    @Published var tags: [String: TagInfo] = [:]
    @Published var snippets: [Snippet] = []
    @Published var settings: NookSettings = NookSettings()
    @Published var confettiToken: UUID?

    private var nextId: Int = 1
    private var nextSnippetId: Int = 1
    private let filePath: URL

    // External-write watcher state
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var watchedFD: Int32 = -1
    /// Suppress reload reactions to our own writes — extend on each save().
    private var ignoreReloadUntil: Date = .distantPast

    static let tagColors: [String] = [
        "#FF6B6B", "#FF8A65", "#FFB74D", "#FFD54F", "#FFF176",
        "#DCE775", "#AED581", "#81C784", "#4DB6AC", "#4DD0E1",
        "#4FC3F7", "#64B5F6", "#7986CB", "#9575CD", "#BA68C8",
        "#CE93D8", "#F06292", "#E57373", "#A1887F", "#90A4AE",
    ]

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dataDir = appSupport.appendingPathComponent("Nook/data")
        try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
        filePath = dataDir.appendingPathComponent("tasks.json")
        let isFirstRun = !FileManager.default.fileExists(atPath: filePath.path)
        load()
        if isFirstRun {
            seedWelcomeTask()
        }
        startWatching()
    }

    /// First-run welcome task + starter snippets — the snippets section at the bottom
    /// holds the actual install command and AI prompts (one-click copy), so the
    /// welcome task can stay short and explain the WHAT, not the HOW.
    private func seedWelcomeTask() {
        let welcomeDesc = """
        Let your AI agent (Claude, Cursor, etc.) drop tasks straight into Nook — no need to switch back to this panel and type.

        ✨ How it works
        Have your AI install the nooktodo CLI once (the command is in Snippets at the bottom). After that, just tell the AI "add a task: X" — it writes to Nook, and this panel updates live.

        📝 Example
        You: "Add a task: buy milk tomorrow, high priority"
        AI runs: nooktodo "buy milk" -p high -d tomorrow
        ↓
        Task appears here instantly ✓

        Tick the subtasks below as you go, then delete this whole task 👋
        """
        let task = NookTask(
            id: 1,
            title: "👋 Let an AI add tasks for you",
            description: welcomeDesc,
            completed: false,
            priority: .none,
            tags: [],
            subtasks: [
                Subtask(id: 1, title: "Copy the [Install nooktodo] snippet from the bottom rail", completed: false),
                Subtask(id: 2, title: "Ask any AI agent (Claude / Cursor) to run that command", completed: false),
                Subtask(id: 3, title: "Tell the AI \"add a task: XX\" and watch it appear here", completed: false),
            ],
            nextSubId: 4,
            dueDate: nil,
            listId: "inbox",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            completedAt: nil
        )
        tasks = [task]
        nextId = 2

        // Starter snippets — give users one-click access to install + AI prompts
        let installCmd = #"NOOK=$(find /Applications ~/Applications -name Nook.app -maxdepth 2 2>/dev/null | head -1) && mkdir -p ~/.local/bin && ln -sf "$NOOK/Contents/Resources/nooktodo" ~/.local/bin/nooktodo && echo "✓ nooktodo installed"#
        let now = ISO8601DateFormatter().string(from: Date())
        snippets = [
            Snippet(id: 1, label: "📦 Install nooktodo (have AI run this)",
                    value: installCmd, type: "command", createdAt: now),
            Snippet(id: 2, label: "💡 AI prompt template",
                    value: "Add a task: X, priority high, due tomorrow",
                    type: "text", createdAt: now),
            Snippet(id: 3, label: "📝 nooktodo command format",
                    value: #"nooktodo "title" -t tag -p high -d tomorrow"#,
                    type: "command", createdAt: now),
        ]
        nextSnippetId = 4

        save()
    }

    deinit {
        fileMonitor?.cancel()
        if watchedFD >= 0 { close(watchedFD) }
    }

    /// Watch the data directory for changes — atomic writes swap inodes, so watching
    /// the file directly would lose the descriptor on every save. The directory
    /// vnode is stable across the rename. Reload whenever any change fires.
    private func startWatching() {
        let dir = filePath.deletingLastPathComponent()
        watchedFD = open(dir.path, O_EVTONLY)
        guard watchedFD >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: watchedFD,
            eventMask: [.write, .extend, .rename, .delete],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.reloadIfExternalChange()
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.watchedFD, fd >= 0 {
                close(fd)
                self?.watchedFD = -1
            }
        }
        source.resume()
        fileMonitor = source
    }

    private func reloadIfExternalChange() {
        // Skip reactions to our own recent saves.
        guard Date() > ignoreReloadUntil else { return }
        load()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: filePath.path) else { return }
        do {
            let data = try Data(contentsOf: filePath)
            let decoded = try JSONDecoder().decode(StoreData.self, from: data)
            tasks = decoded.tasks
            nextId = decoded.nextId
            tags = decoded.tags
            snippets = decoded.snippets
            nextSnippetId = decoded.nextSnippetId
            settings = decoded.settings
        } catch {
            print("[Store] Failed to load: \(error)")
        }
    }

    private func save() {
        let storeData = StoreData(
            tasks: tasks, nextId: nextId,
            tags: tags, snippets: snippets,
            nextSnippetId: nextSnippetId, settings: settings
        )
        // Suppress reload reactions to our own write — atomic write fires multiple
        // dir events (temp create, rename, delete temp).
        ignoreReloadUntil = Date().addingTimeInterval(0.6)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(storeData)
            try data.write(to: filePath, options: .atomic)
        } catch {
            print("[Store] Failed to save: \(error)")
        }
    }

    // MARK: - Tasks

    @discardableResult
    func addTask(title: String, description: String = "", priority: NookTask.Priority = .none, tags: [String] = [], dueDate: String? = nil) -> Int {
        let taskId = nextId
        let task = NookTask(
            id: taskId, title: title.trimmingCharacters(in: .whitespaces),
            description: description, completed: false, priority: priority,
            tags: tags, subtasks: [], nextSubId: 1,
            dueDate: dueDate, listId: "inbox",
            createdAt: ISO8601DateFormatter().string(from: Date()), completedAt: nil
        )
        nextId += 1
        tasks.insert(task, at: 0)
        syncGlobalTags(tags)
        save()
        return taskId
    }

    func toggleTask(_ id: Int) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let wasCompleted = tasks[idx].completed
        tasks[idx].completed.toggle()
        tasks[idx].completedAt = tasks[idx].completed ? ISO8601DateFormatter().string(from: Date()) : nil
        if !wasCompleted {
            confettiToken = UUID()
        }
        save()
    }

    func deleteTask(_ id: Int) {
        tasks.removeAll { $0.id == id }
        save()
    }

    func updateTask(_ id: Int, title: String? = nil, description: String? = nil,
                    priority: NookTask.Priority? = nil, tags: [String]? = nil,
                    dueDate: String?? = nil) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        if let t = title { tasks[idx].title = t }
        if let d = description { tasks[idx].description = d }
        if let p = priority { tasks[idx].priority = p }
        if let tgs = tags {
            tasks[idx].tags = tgs
            syncGlobalTags(tgs)
        }
        if let dd = dueDate { tasks[idx].dueDate = dd }
        save()
    }

    func reorderTask(_ id: Int, to targetIndex: Int) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let task = tasks.remove(at: idx)
        let insertAt = min(targetIndex, tasks.count)
        tasks.insert(task, at: insertAt)
        save()
    }

    func clearCompleted() {
        tasks.removeAll { $0.completed }
        save()
    }

    // MARK: - Subtasks

    func addSubtask(_ taskId: Int, title: String) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let sub = Subtask(id: tasks[idx].nextSubId, title: title.trimmingCharacters(in: .whitespaces), completed: false)
        tasks[idx].nextSubId += 1
        tasks[idx].subtasks.append(sub)
        save()
    }

    func toggleSubtask(_ taskId: Int, subId: Int) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskId }),
              let si = tasks[idx].subtasks.firstIndex(where: { $0.id == subId }) else { return }
        tasks[idx].subtasks[si].completed.toggle()
        save()
    }

    func deleteSubtask(_ taskId: Int, subId: Int) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[idx].subtasks.removeAll { $0.id == subId }
        save()
    }

    func updateSubtask(_ taskId: Int, subId: Int, title: String) {
        guard let idx = tasks.firstIndex(where: { $0.id == taskId }),
              let si = tasks[idx].subtasks.firstIndex(where: { $0.id == subId }) else { return }
        tasks[idx].subtasks[si].title = title.trimmingCharacters(in: .whitespaces)
        save()
    }

    // MARK: - Tags

    func setTagColor(_ name: String, color: String?) {
        tags[name] = TagInfo(color: color)
        save()
    }

    func deleteTag(_ name: String) {
        tags.removeValue(forKey: name)
        for i in tasks.indices {
            tasks[i].tags.removeAll { $0 == name }
        }
        save()
    }

    private func syncGlobalTags(_ tagNames: [String]) {
        for name in tagNames where tags[name] == nil {
            tags[name] = TagInfo(color: nil)
        }
    }

    // MARK: - Snippets

    func addSnippet(label: String, value: String, type: String = "text") {
        let s = Snippet(
            id: nextSnippetId,
            label: label.trimmingCharacters(in: .whitespaces),
            value: value, type: type,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        nextSnippetId += 1
        snippets.append(s)
        save()
    }

    func updateSnippet(_ id: Int, label: String? = nil, value: String? = nil) {
        guard let idx = snippets.firstIndex(where: { $0.id == id }) else { return }
        if let l = label { snippets[idx].label = l }
        if let v = value { snippets[idx].value = v }
        save()
    }

    func deleteSnippet(_ id: Int) {
        snippets.removeAll { $0.id == id }
        save()
    }

    // MARK: - Settings

    func updateSettings(_ newSettings: NookSettings) {
        settings = newSettings
        save()
    }

    func updateCorner(_ corner: NookSettings.CornerTrigger) {
        settings.cornerTrigger = corner
        save()
    }

    func updatePanelSize(heightRatio: Double, width: Double) {
        settings.panelHeightRatio = heightRatio
        settings.panelWidth = width
        save()
    }
}

extension StoreData {
    init(tasks: [NookTask], nextId: Int, tags: [String: TagInfo],
         snippets: [Snippet], nextSnippetId: Int, settings: NookSettings) {
        self.tasks = tasks
        self.nextId = nextId
        self.tags = tags
        self.snippets = snippets
        self.nextSnippetId = nextSnippetId
        self.settings = settings
    }
}
