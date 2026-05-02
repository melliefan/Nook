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
