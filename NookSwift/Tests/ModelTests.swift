import Foundation

// MARK: - NookTask Codable

func testModelCodable() {
    group("NookTask Codable")

    let task = NookTask(
        id: 1, title: "Test Task", description: "desc",
        completed: false, priority: .high,
        tags: ["work", "urgent"], subtasks: [
            Subtask(id: 1, title: "Sub1", completed: false),
            Subtask(id: 2, title: "Sub2", completed: true),
        ],
        nextSubId: 3, dueDate: "2026-04-22",
        listId: "inbox",
        createdAt: "2026-04-22T10:00:00Z",
        completedAt: nil
    )

    // Encode
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    guard let data = try? encoder.encode(task) else {
        check(false, "Encode NookTask")
        return
    }
    check(true, "Encode NookTask")

    // Decode
    guard let decoded = try? JSONDecoder().decode(NookTask.self, from: data) else {
        check(false, "Decode NookTask")
        return
    }
    check(true, "Decode NookTask")
    checkEqual(decoded.id, 1, "Task id preserved")
    checkEqual(decoded.title, "Test Task", "Task title preserved")
    checkEqual(decoded.priority, .high, "Task priority preserved")
    checkEqual(decoded.tags, ["work", "urgent"], "Task tags preserved")
    checkEqual(decoded.subtasks.count, 2, "Subtask count preserved")
    checkEqual(decoded.subtasks[1].completed, true, "Subtask completed state preserved")
    checkEqual(decoded.dueDate, "2026-04-22", "Due date preserved")
    checkNil(decoded.completedAt, "completedAt nil preserved")
    checkEqual(decoded.nextSubId, 3, "nextSubId preserved")

    // Round-trip with completed task
    var completed = task
    completed.completed = true
    completed.completedAt = "2026-04-22T12:00:00Z"
    let data2 = try! encoder.encode(completed)
    let decoded2 = try! JSONDecoder().decode(NookTask.self, from: data2)
    checkEqual(decoded2.completed, true, "Completed flag round-trip")
    checkEqual(decoded2.completedAt, "2026-04-22T12:00:00Z", "completedAt round-trip")
}

// MARK: - Electron JSON Compatibility

func testElectronJSONCompat() {
    group("Electron JSON Compatibility")

    // Simulate the exact JSON structure from Electron's store
    let electronJSON = """
    {
      "tasks": [
        {
          "id": 5,
          "title": "汇报ppt",
          "description": "",
          "completed": false,
          "priority": "none",
          "tags": ["工作", "客户A"],
          "subtasks": [],
          "nextSubId": 1,
          "dueDate": "2026-04-17",
          "listId": "inbox",
          "createdAt": "2026-04-17T00:34:00.775Z",
          "completedAt": null
        },
        {
          "id": 3,
          "title": "Completed task",
          "description": "some desc",
          "completed": true,
          "priority": "high",
          "tags": [],
          "subtasks": [
            {"id": 1, "title": "sub", "completed": true}
          ],
          "nextSubId": 2,
          "dueDate": null,
          "listId": "inbox",
          "createdAt": "2026-04-16T22:00:00.000Z",
          "completedAt": "2026-04-17T10:00:00.000Z"
        }
      ],
      "nextId": 13,
      "tags": {
        "工作": {"color": "#FF6B6B"},
        "客户A": {"color": null},
        "leetvibe": {"color": "#4FC3F7"}
      },
      "snippets": [
        {
          "id": 1,
          "label": "",
          "value": "ssh user@host",
          "type": "text",
          "createdAt": "2026-04-17T09:00:00.000Z"
        }
      ],
      "nextSnippetId": 2,
      "settings": {
        "cornerTrigger": "bottom-left",
        "panelHeightRatio": 0.8961904761904762,
        "panelWidth": 476
      }
    }
    """.data(using: .utf8)!

    // Try to decode as StoreData
    do {
        let decoded = try JSONDecoder().decode(StoreData.self, from: electronJSON)
        check(true, "Decode Electron JSON")
        checkEqual(decoded.tasks.count, 2, "Task count")
        checkEqual(decoded.tasks[0].title, "汇报ppt", "Chinese title decoded")
        checkEqual(decoded.tasks[0].priority, .none, "Priority 'none' decoded")
        checkEqual(decoded.tasks[0].tags, ["工作", "客户A"], "Tags decoded")
        checkEqual(decoded.tasks[0].dueDate, "2026-04-17", "Due date decoded")
        checkNil(decoded.tasks[0].completedAt, "null completedAt decoded as nil")
        checkEqual(decoded.tasks[1].completed, true, "Completed flag decoded")
        checkEqual(decoded.tasks[1].priority, .high, "Priority 'high' decoded")
        checkNotNil(decoded.tasks[1].completedAt, "Non-null completedAt decoded")
        checkEqual(decoded.tasks[1].subtasks.count, 1, "Subtask decoded")
        checkEqual(decoded.nextId, 13, "nextId decoded")

        // Tags
        checkEqual(decoded.tags.count, 3, "Tag count")
        checkEqual(decoded.tags["工作"]?.color, "#FF6B6B", "Tag color decoded")
        checkNil(decoded.tags["客户A"]?.color, "Null tag color decoded as nil")

        // Snippets
        checkEqual(decoded.snippets.count, 1, "Snippet count")
        checkEqual(decoded.snippets[0].value, "ssh user@host", "Snippet value")
        checkEqual(decoded.nextSnippetId, 2, "nextSnippetId")

        // Settings
        checkEqual(decoded.settings.cornerTrigger, .bottomLeft, "Corner trigger decoded")
        check(abs(decoded.settings.panelHeightRatio - 0.896) < 0.01, "Height ratio decoded")
        check(abs(decoded.settings.panelWidth - 476) < 0.01, "Panel width decoded")

        // Re-encode and verify key fields survive
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let reEncoded = try encoder.encode(decoded)
        let reDecoded = try JSONDecoder().decode(StoreData.self, from: reEncoded)
        checkEqual(reDecoded.tasks.count, 2, "Round-trip task count")
        checkEqual(reDecoded.tags.count, 3, "Round-trip tag count")
        checkEqual(reDecoded.settings.cornerTrigger, .bottomLeft, "Round-trip corner")
    } catch {
        check(false, "Decode Electron JSON — \(error)")
    }
}

// MARK: - Priority

func testTaskPriority() {
    group("Task Priority")

    checkEqual(NookTask.Priority.high.order, 0, "High priority order = 0")
    checkEqual(NookTask.Priority.medium.order, 1, "Medium priority order = 1")
    checkEqual(NookTask.Priority.low.order, 2, "Low priority order = 2")
    checkEqual(NookTask.Priority.none.order, 3, "None priority order = 3")

    checkEqual(NookTask.Priority.high.color, "#FF3B30", "High color")
    checkEqual(NookTask.Priority.medium.color, "#FF9500", "Medium color")
    checkEqual(NookTask.Priority.low.color, "#34C759", "Low color")
    checkEqual(NookTask.Priority.none.color, "#8E8E93", "None color")

    checkEqual(NookTask.Priority.high.label, "高优先级", "High label")

    // Raw value encoding
    checkEqual(NookTask.Priority.high.rawValue, "high", "High raw value")
    checkEqual(NookTask.Priority(rawValue: "none"), NookTask.Priority.none, "None from raw value")
    checkNil(NookTask.Priority(rawValue: "invalid"), "Invalid raw value = nil")
}

// MARK: - Date Formatting

func testDateFormatting() {
    group("Date Formatting")

    let today = DateFormatter()
    today.dateFormat = "yyyy-MM-dd"
    let todayStr = today.string(from: Date())

    let cal = Calendar.current
    let tomorrowDate = cal.date(byAdding: .day, value: 1, to: Date())!
    let tomorrowStr = today.string(from: tomorrowDate)

    let yesterdayDate = cal.date(byAdding: .day, value: -1, to: Date())!
    let yesterdayStr = today.string(from: yesterdayDate)

    let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: Date())!
    let threeDaysAgoStr = today.string(from: threeDaysAgo)

    let inFiveDays = cal.date(byAdding: .day, value: 5, to: Date())!
    let inFiveDaysStr = today.string(from: inFiveDays)

    func makeTask(due: String?) -> NookTask {
        NookTask(id: 1, title: "T", description: "", completed: false,
                 priority: .none, tags: [], subtasks: [], nextSubId: 1,
                 dueDate: due, listId: "inbox",
                 createdAt: "2026-01-01T00:00:00Z", completedAt: nil)
    }

    checkEqual(makeTask(due: todayStr).formattedDueDate, "今天", "Today formatted")
    checkEqual(makeTask(due: tomorrowStr).formattedDueDate, "明天", "Tomorrow formatted")
    checkEqual(makeTask(due: yesterdayStr).formattedDueDate, "昨天", "Yesterday formatted")
    checkEqual(makeTask(due: threeDaysAgoStr).formattedDueDate, "3天前", "3 days ago formatted")
    checkEqual(makeTask(due: inFiveDaysStr).formattedDueDate, "5天后", "5 days from now formatted")
    checkNil(makeTask(due: nil).formattedDueDate, "No due date = nil")
    checkNil(makeTask(due: "invalid").formattedDueDate, "Invalid date = nil")
}

// MARK: - Overdue Detection

func testOverdueDetection() {
    group("Overdue Detection")

    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    let cal = Calendar.current

    let yesterday = f.string(from: cal.date(byAdding: .day, value: -1, to: Date())!)
    let today = f.string(from: Date())
    let tomorrow = f.string(from: cal.date(byAdding: .day, value: 1, to: Date())!)

    func makeTask(due: String?, completed: Bool = false) -> NookTask {
        NookTask(id: 1, title: "T", description: "", completed: completed,
                 priority: .none, tags: [], subtasks: [], nextSubId: 1,
                 dueDate: due, listId: "inbox",
                 createdAt: "2026-01-01T00:00:00Z", completedAt: nil)
    }

    check(makeTask(due: yesterday).isOverdue, "Yesterday is overdue")
    check(!makeTask(due: today).isOverdue, "Today is NOT overdue")
    check(!makeTask(due: tomorrow).isOverdue, "Tomorrow is NOT overdue")
    check(!makeTask(due: nil).isOverdue, "No due date is NOT overdue")
    check(!makeTask(due: yesterday, completed: true).isOverdue, "Completed task is NOT overdue")
}

// MARK: - Settings Codable

func testSettingsCodable() {
    group("Settings Codable")

    let allCorners: [NookSettings.CornerTrigger] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    for corner in allCorners {
        let s = NookSettings(cornerTrigger: corner, panelHeightRatio: 0.75, panelWidth: 400)
        let data = try! JSONEncoder().encode(s)
        let decoded = try! JSONDecoder().decode(NookSettings.self, from: data)
        checkEqual(decoded.cornerTrigger, corner, "Corner \(corner.rawValue) round-trip")
    }

    checkEqual(NookSettings.CornerTrigger.topLeft.rawValue, "top-left", "top-left raw value")
    checkEqual(NookSettings.CornerTrigger.bottomRight.rawValue, "bottom-right", "bottom-right raw value")
    check(!NookSettings.CornerTrigger.topLeft.isRight, "topLeft is NOT right")
    check(NookSettings.CornerTrigger.topRight.isRight, "topRight IS right")
    check(!NookSettings.CornerTrigger.topLeft.isBottom, "topLeft is NOT bottom")
    check(NookSettings.CornerTrigger.bottomLeft.isBottom, "bottomLeft IS bottom")
}

// MARK: - Snippet Codable

func testSnippetCodable() {
    group("Snippet Codable")

    let s = Snippet(id: 1, label: "ssh", value: "ssh user@host -p 22", type: "text", createdAt: "2026-04-22T00:00:00Z")
    let data = try! JSONEncoder().encode(s)
    let decoded = try! JSONDecoder().decode(Snippet.self, from: data)
    checkEqual(decoded.id, 1, "Snippet id")
    checkEqual(decoded.label, "ssh", "Snippet label")
    checkEqual(decoded.value, "ssh user@host -p 22", "Snippet value")
    checkEqual(decoded.type, "text", "Snippet type")
}
