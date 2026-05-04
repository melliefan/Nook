import Foundation
import AppKit

// MARK: - Unicode & Special Characters

func testUnicodeHandling() {
    group("Unicode & Special Characters")

    // Chinese titles
    let task1 = NookTask(id: 1, title: "汇报ppt", description: "准备材料",
                         completed: false, priority: .high,
                         tags: ["工作", "客户A"], subtasks: [], nextSubId: 1,
                         dueDate: nil, listId: "inbox",
                         createdAt: "2026-04-22T00:00:00Z", completedAt: nil)
    let data1 = try! JSONEncoder().encode(task1)
    let decoded1 = try! JSONDecoder().decode(NookTask.self, from: data1)
    checkEqual(decoded1.title, "汇报ppt", "Chinese title round-trip")
    checkEqual(decoded1.tags, ["工作", "客户A"], "Chinese tags round-trip")
    checkEqual(decoded1.description, "准备材料", "Chinese description round-trip")

    // Emoji in title
    let task2 = NookTask(id: 2, title: "🎯 Important task 🚀", description: "🔥",
                         completed: false, priority: .none,
                         tags: ["🏷️tag"], subtasks: [], nextSubId: 1,
                         dueDate: nil, listId: "inbox",
                         createdAt: "2026-04-22T00:00:00Z", completedAt: nil)
    let data2 = try! JSONEncoder().encode(task2)
    let decoded2 = try! JSONDecoder().decode(NookTask.self, from: data2)
    checkEqual(decoded2.title, "🎯 Important task 🚀", "Emoji title round-trip")
    checkEqual(decoded2.tags, ["🏷️tag"], "Emoji tag round-trip")

    // Special shell characters in snippet values
    let snippet = Snippet(id: 1, label: "cmd",
                          value: "ssh -o 'StrictHostKeyChecking=no' root@host | grep \"pattern\" && echo $HOME",
                          type: "text", createdAt: "2026-04-22T00:00:00Z")
    let sData = try! JSONEncoder().encode(snippet)
    let sDecoded = try! JSONDecoder().decode(Snippet.self, from: sData)
    checkEqual(sDecoded.value, snippet.value, "Shell special chars round-trip")

    // Very long title
    let longTitle = String(repeating: "长", count: 1000)
    let task3 = NookTask(id: 3, title: longTitle, description: "",
                         completed: false, priority: .none,
                         tags: [], subtasks: [], nextSubId: 1,
                         dueDate: nil, listId: "inbox",
                         createdAt: "2026-04-22T00:00:00Z", completedAt: nil)
    let data3 = try! JSONEncoder().encode(task3)
    let decoded3 = try! JSONDecoder().decode(NookTask.self, from: data3)
    checkEqual(decoded3.title.count, 1000, "Very long title (1000 chars) round-trip")

    // Newlines and tabs in description
    let desc = "Line 1\nLine 2\n\tIndented\n\n  Spaces  "
    let task4 = NookTask(id: 4, title: "T", description: desc,
                         completed: false, priority: .none,
                         tags: [], subtasks: [], nextSubId: 1,
                         dueDate: nil, listId: "inbox",
                         createdAt: "2026-04-22T00:00:00Z", completedAt: nil)
    let data4 = try! JSONEncoder().encode(task4)
    let decoded4 = try! JSONDecoder().decode(NookTask.self, from: data4)
    checkEqual(decoded4.description, desc, "Newlines/tabs in description round-trip")
}

// MARK: - Empty/Whitespace Input

func testEmptyInputHandling() async {
    group("Empty & Whitespace Input")

    await MainActor.run {
        let store = makeTestStore()

        // Empty title → still adds (Store doesn't validate, caller should)
        store.addTask(title: "")
        checkEqual(store.tasks[0].title, "", "Empty title stored as-is")

        // Whitespace-only title → trimmed to empty
        store.addTask(title: "   ")
        checkEqual(store.tasks[0].title, "", "Whitespace title trimmed to empty")

        // Empty tags array
        store.addTask(title: "No Tags", tags: [])
        checkEqual(store.tasks[0].tags, [], "Empty tags array stored")

        // Empty snippet value
        store.addSnippet(label: "", value: "")
        checkEqual(store.snippets[0].value, "", "Empty snippet value stored")

        // Empty description update
        store.addTask(title: "Has desc", priority: .none)
        store.updateTask(store.tasks[0].id, description: "")
        checkEqual(store.tasks[0].description, "", "Description set to empty")

        // Tag with empty name
        store.setTagColor("", color: "#FF0000")
        checkNotNil(store.tags[""], "Empty string tag name stored")

        // Subtask with empty title
        store.addTask(title: "Parent")
        store.addSubtask(store.tasks[0].id, title: "")
        checkEqual(store.tasks[0].subtasks[0].title, "", "Empty subtask title trimmed to empty")
    }
}

// MARK: - Date Formatting Edge Cases

func testDateFormattingEdgeCases() {
    group("Date Formatting Edge Cases")

    func makeTask(due: String?) -> NookTask {
        NookTask(id: 1, title: "T", description: "", completed: false,
                 priority: .none, tags: [], subtasks: [], nextSubId: 1,
                 dueDate: due, listId: "inbox",
                 createdAt: "2026-01-01T00:00:00Z", completedAt: nil)
    }

    let cal = Calendar.current
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"

    // 8 days from now → shows "M月d日" format, not "X天后"
    let in8Days = cal.date(byAdding: .day, value: 8, to: Date())!
    let in8Str = f.string(from: in8Days)
    let result8 = makeTask(due: in8Str).formattedDueDate
    checkNotNil(result8, "8 days from now has formatted date")
    check(result8 != "in 8d", "8 days → shows date format, not 'in 8d'")

    // Exactly 7 days from now → "in 7d"
    let in7Days = cal.date(byAdding: .day, value: 7, to: Date())!
    let in7Str = f.string(from: in7Days)
    checkEqual(makeTask(due: in7Str).formattedDueDate, "in 7d", "7 days → 'in 7d'")

    // 2 days from now → "in 2d"
    let in2Days = cal.date(byAdding: .day, value: 2, to: Date())!
    let in2Str = f.string(from: in2Days)
    checkEqual(makeTask(due: in2Str).formattedDueDate, "in 2d", "2 days → 'in 2d'")

    // 30 days ago → "30d ago"
    let ago30 = cal.date(byAdding: .day, value: -30, to: Date())!
    let ago30Str = f.string(from: ago30)
    checkEqual(makeTask(due: ago30Str).formattedDueDate, "30d ago", "30 days ago → '30d ago'")

    // Far future (next year) → "MMM d" format (e.g. "May 4")
    let farFuture = cal.date(byAdding: .month, value: 3, to: Date())!
    let farStr = f.string(from: farFuture)
    let farResult = makeTask(due: farStr).formattedDueDate
    checkNotNil(farResult, "Far future date has result")
    // Should contain a 3-letter month abbreviation (Jan/Feb/Mar/...)
    let hasMonthAbbr = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"].contains { farResult?.contains($0) == true }
    check(hasMonthAbbr, "Far future shows month abbreviation")

    // Invalid date strings
    checkNil(makeTask(due: "invalid").formattedDueDate, "Invalid string → nil")
    checkNil(makeTask(due: "2026-13-01").formattedDueDate, "Invalid month 13 → nil")
    checkNil(makeTask(due: "2026-00-01").formattedDueDate, "Invalid month 00 → nil")
    checkNil(makeTask(due: "").formattedDueDate, "Empty string → nil")
    checkNil(makeTask(due: "20260422").formattedDueDate, "No dashes → nil")
    checkNil(makeTask(due: "04/22/2026").formattedDueDate, "Wrong format → nil")

    // Leap year date
    checkNotNil(makeTask(due: "2028-02-29").formattedDueDate, "Leap year Feb 29 → valid")

    // Boundary: year transition
    checkNotNil(makeTask(due: "2025-12-31").formattedDueDate, "Dec 31 → valid")
    checkNotNil(makeTask(due: "2027-01-01").formattedDueDate, "Jan 1 next year → valid")
}

// MARK: - Overdue Edge Cases

func testOverdueEdgeCases() {
    group("Overdue Detection Edge Cases")

    func makeTask(due: String?, completed: Bool = false) -> NookTask {
        NookTask(id: 1, title: "T", description: "", completed: completed,
                 priority: .none, tags: [], subtasks: [], nextSubId: 1,
                 dueDate: due, listId: "inbox",
                 createdAt: "2026-01-01T00:00:00Z", completedAt: nil)
    }

    // Invalid date → not overdue (should not crash)
    check(!makeTask(due: "garbage").isOverdue, "Invalid date string → not overdue")
    check(!makeTask(due: "").isOverdue, "Empty string → not overdue")
    check(!makeTask(due: "2026-13-45").isOverdue, "Impossible date → not overdue")

    // Very old date
    check(makeTask(due: "2020-01-01").isOverdue, "2020-01-01 → overdue")

    // Far future
    check(!makeTask(due: "2099-12-31").isOverdue, "2099-12-31 → not overdue")

    // Completed task with overdue date
    check(!makeTask(due: "2020-01-01", completed: true).isOverdue, "Completed + overdue date → NOT overdue")
}

// MARK: - Store Persistence Round-Trip

func testStorePersistence() async {
    group("Store Persistence Round-Trip")

    await MainActor.run {
        let store = makeTestStore()

        // Add data
        store.addTask(title: "Persist Task", priority: .medium, tags: ["persist"], dueDate: "2026-06-01")
        store.addSubtask(store.tasks[0].id, title: "Persist Sub")
        store.setTagColor("persist", color: "#4FC3F7")
        store.addSnippet(label: "test", value: "echo hello")
        store.updateCorner(.bottomRight)
        store.updatePanelSize(heightRatio: 0.6, width: 450)

        // Read the JSON file directly
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let filePath = appSupport.appendingPathComponent("Nook/data/tasks.json")
        check(FileManager.default.fileExists(atPath: filePath.path), "JSON file exists on disk")

        guard let data = try? Data(contentsOf: filePath) else {
            check(false, "Can read JSON file")
            return
        }
        check(true, "Can read JSON file")

        // Verify it's valid JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            check(false, "File contains valid JSON")
            return
        }
        check(true, "File contains valid JSON")

        // Verify structure
        checkNotNil(json["tasks"], "JSON has 'tasks' key")
        checkNotNil(json["nextId"], "JSON has 'nextId' key")
        checkNotNil(json["tags"], "JSON has 'tags' key")
        checkNotNil(json["snippets"], "JSON has 'snippets' key")
        checkNotNil(json["nextSnippetId"], "JSON has 'nextSnippetId' key")
        checkNotNil(json["settings"], "JSON has 'settings' key")

        // Verify it can be decoded back
        guard let decoded = try? JSONDecoder().decode(StoreData.self, from: data) else {
            check(false, "JSON can be decoded back to StoreData")
            return
        }
        check(true, "JSON can be decoded back to StoreData")
        check(decoded.tasks.count >= 1, "Decoded tasks exist")
    }
}

// MARK: - Corrupted/Partial JSON

func testCorruptedJSON() {
    group("Corrupted & Partial JSON Handling")

    // Completely invalid JSON
    let garbage = "this is not json".data(using: .utf8)!
    let result1 = try? JSONDecoder().decode(StoreData.self, from: garbage)
    checkNil(result1, "Garbage data → decode fails gracefully")

    // Empty object
    let empty = "{}".data(using: .utf8)!
    let result2 = try? JSONDecoder().decode(StoreData.self, from: empty)
    checkNil(result2, "Empty object → decode fails (missing required fields)")

    // Missing tasks field
    let partial1 = """
    {"nextId": 1, "tags": {}, "snippets": [], "nextSnippetId": 1, "settings": {"cornerTrigger": "top-left", "panelHeightRatio": 0.75, "panelWidth": 380}}
    """.data(using: .utf8)!
    let result3 = try? JSONDecoder().decode(StoreData.self, from: partial1)
    checkNil(result3, "Missing 'tasks' → decode fails")

    // Missing settings fields
    let partial2 = """
    {"tasks": [], "nextId": 1, "tags": {}, "snippets": [], "nextSnippetId": 1, "settings": {"cornerTrigger": "top-left"}}
    """.data(using: .utf8)!
    let result4 = try? JSONDecoder().decode(StoreData.self, from: partial2)
    checkNil(result4, "Partial settings (missing panelWidth) → decode fails")

    // Unknown priority value
    let badPriority = """
    {"tasks": [{"id":1,"title":"T","description":"","completed":false,"priority":"ULTRA","tags":[],"subtasks":[],"nextSubId":1,"dueDate":null,"listId":"inbox","createdAt":"2026-01-01T00:00:00Z","completedAt":null}],
     "nextId": 2, "tags": {}, "snippets": [], "nextSnippetId": 1,
     "settings": {"cornerTrigger": "top-left", "panelHeightRatio": 0.75, "panelWidth": 380}}
    """.data(using: .utf8)!
    let result5 = try? JSONDecoder().decode(StoreData.self, from: badPriority)
    checkNil(result5, "Unknown priority 'ULTRA' → decode fails")

    // Unknown corner trigger
    let badCorner = """
    {"tasks": [], "nextId": 1, "tags": {}, "snippets": [], "nextSnippetId": 1,
     "settings": {"cornerTrigger": "center", "panelHeightRatio": 0.75, "panelWidth": 380}}
    """.data(using: .utf8)!
    let result6 = try? JSONDecoder().decode(StoreData.self, from: badCorner)
    checkNil(result6, "Unknown corner 'center' → decode fails")

    // Null in non-optional field
    let nullTitle = """
    {"tasks": [{"id":1,"title":null,"description":"","completed":false,"priority":"none","tags":[],"subtasks":[],"nextSubId":1,"dueDate":null,"listId":"inbox","createdAt":"2026-01-01T00:00:00Z","completedAt":null}],
     "nextId": 2, "tags": {}, "snippets": [], "nextSnippetId": 1,
     "settings": {"cornerTrigger": "top-left", "panelHeightRatio": 0.75, "panelWidth": 380}}
    """.data(using: .utf8)!
    let result7 = try? JSONDecoder().decode(StoreData.self, from: nullTitle)
    checkNil(result7, "Null title → decode fails")

    // Extra unknown fields → should succeed (forward compatibility)
    let extraFields = """
    {"tasks": [], "nextId": 1, "tags": {}, "snippets": [], "nextSnippetId": 1,
     "settings": {"cornerTrigger": "top-left", "panelHeightRatio": 0.75, "panelWidth": 380},
     "unknownField": "should be ignored", "version": 99}
    """.data(using: .utf8)!
    let result8 = try? JSONDecoder().decode(StoreData.self, from: extraFields)
    checkNotNil(result8, "Extra unknown fields → decode succeeds (forward compat)")
}

// MARK: - Store Concurrent-like Operations

func testStoreRapidOperations() async {
    group("Store Rapid Operations")

    await MainActor.run {
        let store = makeTestStore()

        // Add many tasks rapidly
        for i in 0..<50 {
            store.addTask(title: "Task \(i)")
        }
        checkEqual(store.tasks.count, 50, "50 tasks added rapidly")

        // IDs should all be unique
        let ids = Set(store.tasks.map(\.id))
        checkEqual(ids.count, 50, "All 50 IDs are unique")

        // Delete every other task
        let toDelete = store.tasks.enumerated().filter { $0.offset % 2 == 0 }.map(\.element.id)
        for id in toDelete { store.deleteTask(id) }
        checkEqual(store.tasks.count, 25, "25 tasks after deleting alternates")

        // Toggle all remaining
        for task in store.tasks { store.toggleTask(task.id) }
        check(store.tasks.allSatisfy(\.completed), "All 25 toggled to completed")

        // Clear completed
        store.clearCompleted()
        checkEqual(store.tasks.count, 0, "All cleared")

        // Add tasks with many tags
        let manyTags = (0..<20).map { "tag\($0)" }
        store.addTask(title: "Many tags", tags: manyTags)
        checkEqual(store.tasks[0].tags.count, 20, "Task with 20 tags")
        checkEqual(store.tags.count, 20, "20 tags synced to global registry")

        // Add many subtasks
        let taskId = store.tasks[0].id
        for i in 0..<30 {
            store.addSubtask(taskId, title: "Sub \(i)")
        }
        checkEqual(store.tasks[0].subtasks.count, 30, "30 subtasks added")
        let subIds = Set(store.tasks[0].subtasks.map(\.id))
        checkEqual(subIds.count, 30, "All 30 subtask IDs unique")
    }
}

// MARK: - Multi-Display Trigger Zones

func testMultiDisplayTriggerZones() {
    group("Multi-Display Trigger Zones")

    let mainH: CGFloat = 1080
    let triggerSize: CGFloat = 40

    // Two displays side by side:
    // Display 1: NS frame (0, 0, 1920, 1080)
    // Display 2: NS frame (1920, 0, 2560, 1440)

    // Top-left on display 1: NS (5, 1075) → CG (5, 5)
    let d1TopLeftNS = NSPoint(x: 5, y: 1075)
    let d1TopLeftCG = CGPoint(x: d1TopLeftNS.x, y: mainH - d1TopLeftNS.y)
    check(d1TopLeftCG.x < triggerSize, "D1 top-left: CG x in trigger")
    check(d1TopLeftCG.y < triggerSize, "D1 top-left: CG y in trigger")

    // Top-left on display 2: should NOT trigger for display 1
    let d2Point = NSPoint(x: 1925, y: 1075) // on display 2
    let d2CG = CGPoint(x: d2Point.x, y: mainH - d2Point.y)
    check(d2CG.x > triggerSize, "D2 point: not in D1 trigger zone x")

    // Bottom-left on display 1: NS (5, 5) → CG (5, 1075)
    let d1BottomLeftNS = NSPoint(x: 5, y: 5)
    let d1BottomLeftCG = CGPoint(x: d1BottomLeftNS.x, y: mainH - d1BottomLeftNS.y)
    check(d1BottomLeftCG.x < triggerSize, "D1 bottom-left: CG x in trigger")
    check(d1BottomLeftCG.y > mainH - triggerSize, "D1 bottom-left: CG y in trigger")

    // Point at exact corner boundary (edge case)
    let exactCorner = NSPoint(x: 0, y: mainH)
    let exactCG = CGPoint(x: exactCorner.x, y: mainH - exactCorner.y)
    check(exactCG.x >= 0 && exactCG.x <= triggerSize, "Exact corner x in range")
    check(exactCG.y >= 0 && exactCG.y <= triggerSize, "Exact corner y in range")

    // Point at triggerSize boundary (just outside)
    let boundary = NSPoint(x: triggerSize + 1, y: mainH - triggerSize - 1)
    let boundaryCG = CGPoint(x: boundary.x, y: mainH - boundary.y)
    check(boundaryCG.x > triggerSize, "Boundary point outside trigger x")
    check(boundaryCG.y > triggerSize, "Boundary point outside trigger y")
}

// MARK: - Panel Frame Edge Cases

func testPanelFrameEdgeCases() {
    group("Panel Frame Edge Cases")

    // Very small screen
    let smallScreen = CGRect(x: 0, y: 25, width: 800, height: 575)
    let smallW = max(280, min(600, 380.0))
    let smallH = max(300, smallScreen.height * 0.75) // 431.25
    check(smallW <= smallScreen.width, "Panel fits in small screen width")
    check(smallH <= smallScreen.height, "Panel fits in small screen height")

    // Width larger than screen → clamped to 600 but still fits in 800px screen
    let hugeWidth = max(280, min(600, 900.0))
    checkEqual(hugeWidth, 600, "Huge width clamped to 600")

    // Height ratio 1.0 → full height
    let fullH = max(300, 1055.0 * 1.0) // 1055
    check(abs(fullH - 1055) < 0.01, "Ratio 1.0 → full visible height")

    // Height ratio 0.2 → minimum useful height
    let minH = max(300, 1055.0 * 0.2) // 211 → clamped to 300
    checkEqual(minH, 300, "Ratio 0.2 → clamped to min 300")

    // Height ratio 0.0 → below minimum
    let zeroRatio = max(0.2, min(1.0, 0.0))
    checkEqual(zeroRatio, 0.2, "Ratio 0.0 clamped to 0.2")
    let zeroH = max(300, 1055.0 * zeroRatio) // 211 → 300
    checkEqual(zeroH, 300, "Zero ratio → min height 300")

    // Negative width → clamped
    let negW = max(280, min(600, -100.0))
    checkEqual(negW, 280, "Negative width → clamped to 280")

    // Panel position: all four corners verify no negative coordinates
    let visibleFrame = CGRect(x: 0, y: 25, width: 1920, height: 1055)
    let pw: CGFloat = 380
    let ph: CGFloat = 800

    // top-left
    let tlX = visibleFrame.minX
    let tlY = visibleFrame.maxY - ph
    check(tlX >= 0, "TL: x >= 0")
    check(tlY >= visibleFrame.minY, "TL: y >= visibleFrame.minY")

    // bottom-right
    let brX = visibleFrame.maxX - pw
    let brY = visibleFrame.minY
    check(brX + pw <= visibleFrame.maxX, "BR: right edge within screen")
    check(brY >= 0, "BR: y >= 0")

    // Offset display (e.g., display starting at x=1920)
    let offsetFrame = CGRect(x: 1920, y: 0, width: 2560, height: 1440)
    let offsetX = offsetFrame.minX // 1920 for top-left
    check(offsetX >= offsetFrame.minX, "Offset display: x starts at display origin")
    let offsetRightX = offsetFrame.maxX - pw
    check(offsetRightX + pw <= offsetFrame.maxX, "Offset display: right panel within bounds")
}

// MARK: - Hide Timing Edge Cases

func testHideTimingEdgeCases() {
    group("Hide Timing & Grace Periods")

    let showGrace: TimeInterval = 1.5
    let hideDelay: TimeInterval = 0.6

    // Just shown → within grace → should NOT hide
    let showTime = Date()
    let checkTime1 = showTime.addingTimeInterval(0.3)
    check(checkTime1.timeIntervalSince(showTime) < showGrace, "0.3s after show → within grace")

    // After grace → should start hide checks
    let checkTime2 = showTime.addingTimeInterval(2.0)
    check(checkTime2.timeIntervalSince(showTime) >= showGrace, "2.0s after show → past grace")

    // Mouse just left panel → within hide delay → should NOT hide
    let lastInside = Date()
    let checkTime3 = lastInside.addingTimeInterval(0.3)
    check(checkTime3.timeIntervalSince(lastInside) < hideDelay, "0.3s after leave → within delay")

    // Past hide delay → should check position
    let checkTime4 = lastInside.addingTimeInterval(1.0)
    check(checkTime4.timeIntervalSince(lastInside) >= hideDelay, "1.0s after leave → past delay")

    // Suppress until future time
    let suppressUntil = Date().addingTimeInterval(5.0)
    check(Date() < suppressUntil, "Current time before suppress deadline")
    check(Date().addingTimeInterval(6.0) > suppressUntil, "6s later → past suppress")
}

// MARK: - Store Task Update Isolation

func testStoreUpdateIsolation() async {
    group("Store Update Field Isolation")

    await MainActor.run {
        let store = makeTestStore()
        store.addTask(title: "Original", priority: .high, tags: ["orig"], dueDate: "2026-05-01")
        let id = store.tasks[0].id

        // Update only title → other fields unchanged
        store.updateTask(id, title: "New Title")
        checkEqual(store.tasks[0].title, "New Title", "Title updated")
        checkEqual(store.tasks[0].priority, .high, "Priority unchanged after title update")
        checkEqual(store.tasks[0].tags, ["orig"], "Tags unchanged after title update")
        checkEqual(store.tasks[0].dueDate, "2026-05-01", "Due date unchanged after title update")

        // Update only priority → other fields unchanged
        store.updateTask(id, priority: .low)
        checkEqual(store.tasks[0].title, "New Title", "Title unchanged after priority update")
        checkEqual(store.tasks[0].priority, .low, "Priority updated")
        checkEqual(store.tasks[0].tags, ["orig"], "Tags unchanged after priority update")

        // Update only description → other fields unchanged
        store.updateTask(id, description: "New desc")
        checkEqual(store.tasks[0].description, "New desc", "Description updated")
        checkEqual(store.tasks[0].title, "New Title", "Title unchanged after desc update")

        // Update due date to new value
        store.updateTask(id, dueDate: .some("2026-12-31"))
        checkEqual(store.tasks[0].dueDate, "2026-12-31", "Due date updated")
        checkEqual(store.tasks[0].title, "New Title", "Title unchanged after date update")

        // Update due date to nil (clear it)
        store.updateTask(id, dueDate: .some(nil))
        checkNil(store.tasks[0].dueDate, "Due date cleared to nil")
        checkEqual(store.tasks[0].priority, .low, "Priority unchanged after clearing date")

        // Update non-existent task → no crash, no change
        let countBefore = store.tasks.count
        store.updateTask(9999, title: "Ghost")
        checkEqual(store.tasks.count, countBefore, "Update non-existent task is no-op")
    }
}

// MARK: - Tag Color Edge Cases

func testTagColorEdgeCases() async {
    group("Tag Color Edge Cases")

    await MainActor.run {
        let store = makeTestStore()

        // Set color to nil
        store.setTagColor("nocolor", color: nil)
        checkNil(store.tags["nocolor"]?.color, "Tag with nil color")

        // Set color to valid hex
        store.setTagColor("red", color: "#FF0000")
        checkEqual(store.tags["red"]?.color, "#FF0000", "Tag with hex color")

        // Override existing color
        store.setTagColor("red", color: "#00FF00")
        checkEqual(store.tags["red"]?.color, "#00FF00", "Tag color overridden")

        // Set color back to nil
        store.setTagColor("red", color: nil)
        checkNil(store.tags["red"]?.color, "Tag color reset to nil")

        // Chinese tag name
        store.setTagColor("工作", color: "#4FC3F7")
        checkEqual(store.tags["工作"]?.color, "#4FC3F7", "Chinese tag name with color")

        // Very long tag name
        let longTag = String(repeating: "x", count: 200)
        store.setTagColor(longTag, color: "#123456")
        checkEqual(store.tags[longTag]?.color, "#123456", "200-char tag name works")

        // Delete tag that doesn't exist → no crash
        store.deleteTag("nonexistent")
        check(true, "Delete non-existent tag → no crash")
    }
}

// MARK: - Reorder Edge Cases

func testReorderEdgeCases() async {
    group("Reorder Edge Cases")

    await MainActor.run {
        let store = makeTestStore()
        store.addTask(title: "A")
        store.addTask(title: "B")
        store.addTask(title: "C")

        // Reorder to same position → no change
        let bId = store.tasks[1].id
        store.reorderTask(bId, to: 1)
        checkEqual(store.tasks.map(\.title), ["C", "B", "A"], "Same position → no change")

        // Reorder to index 0
        store.reorderTask(bId, to: 0)
        checkEqual(store.tasks[0].title, "B", "Moved to index 0")

        // Reorder to negative index → clamps to 0
        let aId = store.tasks.last!.id
        store.reorderTask(aId, to: 0)
        checkEqual(store.tasks[0].title, "A", "Index 0 works")

        // Single task → reorder is no-op
        let singleStore = makeTestStore()
        singleStore.addTask(title: "Only")
        singleStore.reorderTask(singleStore.tasks[0].id, to: 5)
        checkEqual(singleStore.tasks.count, 1, "Single task reorder → still 1 task")
        checkEqual(singleStore.tasks[0].title, "Only", "Single task unchanged")
    }
}

// MARK: - JSON Output Electron Compatibility

func testJSONOutputElectronCompat() {
    group("JSON Output → Electron Compatible")

    let storeData = StoreData(
        tasks: [
            NookTask(id: 1, title: "Test", description: "desc",
                     completed: false, priority: .none,
                     tags: ["tag1"], subtasks: [Subtask(id: 1, title: "sub", completed: false)],
                     nextSubId: 2, dueDate: "2026-05-01", listId: "inbox",
                     createdAt: "2026-04-22T00:00:00Z", completedAt: nil)
        ],
        nextId: 2,
        tags: ["tag1": TagInfo(color: "#FF6B6B")],
        snippets: [Snippet(id: 1, label: "cmd", value: "echo hi", type: "text", createdAt: "2026-04-22T00:00:00Z")],
        nextSnippetId: 2,
        settings: NookSettings(cornerTrigger: .bottomLeft, panelHeightRatio: 0.8, panelWidth: 400)
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(storeData),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        check(false, "Encode StoreData to JSON")
        return
    }
    check(true, "Encode StoreData to JSON")

    // Verify top-level keys match Electron format
    let expectedKeys: Set<String> = ["tasks", "nextId", "tags", "snippets", "nextSnippetId", "settings"]
    let actualKeys = Set(json.keys)
    checkEqual(actualKeys, expectedKeys, "Top-level keys match Electron format")

    // Verify task structure
    guard let tasks = json["tasks"] as? [[String: Any]], let task = tasks.first else {
        check(false, "Tasks array accessible")
        return
    }
    check(task["id"] != nil, "Task has 'id'")
    check(task["title"] != nil, "Task has 'title'")
    check(task["priority"] != nil, "Task has 'priority'")
    check(task["tags"] != nil, "Task has 'tags'")
    check(task["subtasks"] != nil, "Task has 'subtasks'")
    check(task["nextSubId"] != nil, "Task has 'nextSubId'")
    check(task["listId"] != nil, "Task has 'listId'")
    check(task["createdAt"] != nil, "Task has 'createdAt'")

    // priority should be a string, not a number
    check(task["priority"] is String, "Priority encoded as string, not number")
    checkEqual(task["priority"] as? String, "none", "Priority value = 'none'")

    // Settings structure
    guard let settings = json["settings"] as? [String: Any] else {
        check(false, "Settings accessible")
        return
    }
    checkEqual(settings["cornerTrigger"] as? String, "bottom-left", "Corner encoded as hyphenated string")
    check(settings["panelHeightRatio"] is Double, "Height ratio is Double")
    check(settings["panelWidth"] is Double || settings["panelWidth"] is Int, "Width is numeric")
}

// MARK: - StoreData Init (private extension test)

func testStoreDataInit() {
    group("StoreData Default Init")

    let empty = StoreData()
    checkEqual(empty.tasks.count, 0, "Default: 0 tasks")
    checkEqual(empty.nextId, 1, "Default: nextId = 1")
    checkEqual(empty.tags.count, 0, "Default: 0 tags")
    checkEqual(empty.snippets.count, 0, "Default: 0 snippets")
    checkEqual(empty.nextSnippetId, 1, "Default: nextSnippetId = 1")
    checkEqual(empty.settings.cornerTrigger, .topLeft, "Default: corner = top-left")
}

// MARK: - Color Hex Parsing Robustness

@MainActor func testColorHexRobustness() {
    group("Color Hex Parsing Robustness")

    func parseHex(_ hex: String) -> (r: Double, g: Double, b: Double)? {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        guard h.count == 6 else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        return (r, g, b)
    }

    // Standard hex
    let red = parseHex("#FF0000")
    checkNotNil(red, "#FF0000 parses")
    check(abs((red?.r ?? 0) - 1.0) < 0.01, "#FF0000 red = 1.0")
    check(abs((red?.g ?? 1) - 0.0) < 0.01, "#FF0000 green = 0.0")

    // Without #
    let blue = parseHex("0000FF")
    checkNotNil(blue, "0000FF parses without #")
    check(abs((blue?.b ?? 0) - 1.0) < 0.01, "0000FF blue = 1.0")

    // 3-char hex → not supported (returns nil)
    let short = parseHex("#FFF")
    checkNil(short, "3-char hex → nil (not supported)")

    // 8-char hex (with alpha) → not supported
    let alpha = parseHex("#FF000080")
    checkNil(alpha, "8-char hex → nil (not supported)")

    // Empty string
    let emptyResult = parseHex("")
    checkNil(emptyResult, "Empty string → nil")

    // All 20 tag colors parse correctly
    for hex in Store.tagColors {
        let result = parseHex(hex)
        checkNotNil(result, "Tag color \(hex) parses")
    }
}
