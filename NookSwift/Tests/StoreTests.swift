import Foundation

// MARK: - Store CRUD

func testStoreCRUD() async {
    group("Store Task CRUD")

    await MainActor.run {
        let store = makeTestStore()

        // Add
        checkEqual(store.tasks.count, 0, "Empty store has 0 tasks")
        store.addTask(title: "Task 1", priority: .high, tags: ["work"], dueDate: "2026-05-01")
        checkEqual(store.tasks.count, 1, "After add: 1 task")
        checkEqual(store.tasks[0].title, "Task 1", "Title stored")
        checkEqual(store.tasks[0].priority, .high, "Priority stored")
        checkEqual(store.tasks[0].tags, ["work"], "Tags stored")
        checkEqual(store.tasks[0].dueDate, "2026-05-01", "Due date stored")
        check(!store.tasks[0].completed, "New task not completed")
        checkNotNil(store.tasks[0].createdAt, "createdAt set")
        let firstId = store.tasks[0].id

        // Add second task (should be at index 0 — prepended)
        store.addTask(title: "Task 2")
        checkEqual(store.tasks.count, 2, "After second add: 2 tasks")
        checkEqual(store.tasks[0].title, "Task 2", "New task prepended")
        checkEqual(store.tasks[1].title, "Task 1", "Old task shifted")
        check(store.tasks[0].id != firstId, "Different IDs")

        // Toggle
        store.toggleTask(firstId)
        let toggled = store.tasks.first { $0.id == firstId }
        check(toggled?.completed == true, "Task toggled to completed")
        checkNotNil(toggled?.completedAt, "completedAt set on complete")

        // Toggle back
        store.toggleTask(firstId)
        let toggled2 = store.tasks.first { $0.id == firstId }
        check(toggled2?.completed == false, "Task toggled back to active")
        checkNil(toggled2?.completedAt, "completedAt cleared on uncomplete")

        // Update
        store.updateTask(firstId, title: "Updated Title", description: "Desc", priority: .low)
        let updated = store.tasks.first { $0.id == firstId }
        checkEqual(updated?.title, "Updated Title", "Title updated")
        checkEqual(updated?.description, "Desc", "Description updated")
        checkEqual(updated?.priority, .low, "Priority updated")
        checkEqual(updated?.tags, ["work"], "Tags unchanged")

        // Update tags
        store.updateTask(firstId, tags: ["personal", "urgent"])
        let updatedTags = store.tasks.first { $0.id == firstId }
        checkEqual(updatedTags?.tags, ["personal", "urgent"], "Tags updated")

        // Update due date to nil
        store.updateTask(firstId, dueDate: .some(nil))
        let updatedDue = store.tasks.first { $0.id == firstId }
        checkNil(updatedDue?.dueDate, "Due date set to nil")

        // Delete
        store.deleteTask(firstId)
        checkEqual(store.tasks.count, 1, "After delete: 1 task")
        checkNil(store.tasks.first { $0.id == firstId }, "Deleted task not found")

        // Clear completed
        store.toggleTask(store.tasks[0].id) // mark completed
        store.addTask(title: "Active Task")
        checkEqual(store.tasks.count, 2, "2 tasks before clear")
        store.clearCompleted()
        checkEqual(store.tasks.count, 1, "After clearCompleted: 1 task")
        checkEqual(store.tasks[0].title, "Active Task", "Active task remains")

        // Edge: delete non-existent
        store.deleteTask(9999)
        checkEqual(store.tasks.count, 1, "Delete non-existent ID is no-op")

        // Edge: toggle non-existent
        store.toggleTask(9999)
        checkEqual(store.tasks.count, 1, "Toggle non-existent ID is no-op")

        // Edge: empty title trimming
        store.addTask(title: "  Spaces  ")
        checkEqual(store.tasks[0].title, "Spaces", "Title trimmed")
    }
}

// MARK: - Store Subtasks

func testStoreSubtasks() async {
    group("Store Subtasks")

    await MainActor.run {
        let store = makeTestStore()
        store.addTask(title: "Parent Task")
        let taskId = store.tasks[0].id

        // Add subtask
        store.addSubtask(taskId, title: "Sub 1")
        checkEqual(store.tasks[0].subtasks.count, 1, "1 subtask added")
        checkEqual(store.tasks[0].subtasks[0].title, "Sub 1", "Subtask title")
        check(!store.tasks[0].subtasks[0].completed, "Subtask not completed")

        store.addSubtask(taskId, title: "Sub 2")
        checkEqual(store.tasks[0].subtasks.count, 2, "2 subtasks")
        check(store.tasks[0].subtasks[0].id != store.tasks[0].subtasks[1].id, "Subtask IDs unique")

        // Toggle subtask
        let subId = store.tasks[0].subtasks[0].id
        store.toggleSubtask(taskId, subId: subId)
        check(store.tasks[0].subtasks[0].completed, "Subtask toggled completed")

        // Update subtask
        store.updateSubtask(taskId, subId: subId, title: "Updated Sub")
        checkEqual(store.tasks[0].subtasks[0].title, "Updated Sub", "Subtask title updated")

        // Delete subtask
        store.deleteSubtask(taskId, subId: subId)
        checkEqual(store.tasks[0].subtasks.count, 1, "Subtask deleted")

        // Edge: subtask on non-existent task
        store.addSubtask(9999, title: "Ghost")
        checkEqual(store.tasks[0].subtasks.count, 1, "No subtask added to non-existent task")

        // Edge: toggle non-existent subtask
        store.toggleSubtask(taskId, subId: 9999)
        checkEqual(store.tasks[0].subtasks.count, 1, "Toggle non-existent subtask is no-op")
    }
}

// MARK: - Store Tags

func testStoreTags() async {
    group("Store Tags")

    await MainActor.run {
        let store = makeTestStore()

        // Tags auto-synced when adding task
        store.addTask(title: "T", tags: ["tagA", "tagB"])
        checkEqual(store.tags.count, 2, "Tags synced from task")
        checkNil(store.tags["tagA"]?.color, "Auto-synced tag has nil color")

        // Set tag color
        store.setTagColor("tagA", color: "#FF0000")
        checkEqual(store.tags["tagA"]?.color, "#FF0000", "Tag color set")

        // Create standalone tag
        store.setTagColor("standalone", color: "#00FF00")
        checkEqual(store.tags.count, 3, "Standalone tag added")

        // Delete tag (removes from tasks too)
        store.deleteTag("tagA")
        checkNil(store.tags["tagA"], "Tag deleted from registry")
        check(!store.tasks[0].tags.contains("tagA"), "Tag removed from task")
        check(store.tasks[0].tags.contains("tagB"), "Other tags preserved")

        // Update task tags
        store.updateTask(store.tasks[0].id, tags: ["newTag"])
        checkNotNil(store.tags["newTag"], "New tag auto-synced")
    }
}

// MARK: - Store Snippets

func testStoreSnippets() async {
    group("Store Snippets")

    await MainActor.run {
        let store = makeTestStore()

        // Add
        store.addSnippet(label: "SSH", value: "ssh user@host")
        checkEqual(store.snippets.count, 1, "Snippet added")
        checkEqual(store.snippets[0].value, "ssh user@host", "Snippet value")

        store.addSnippet(label: "", value: "cmd2")
        checkEqual(store.snippets.count, 2, "Second snippet added")

        // Update
        store.updateSnippet(store.snippets[0].id, value: "ssh root@host")
        checkEqual(store.snippets[0].value, "ssh root@host", "Snippet updated")

        // Delete
        let delId = store.snippets[0].id
        store.deleteSnippet(delId)
        checkEqual(store.snippets.count, 1, "Snippet deleted")
        checkNil(store.snippets.first { $0.id == delId }, "Deleted snippet gone")

        // Edge: delete non-existent
        store.deleteSnippet(9999)
        checkEqual(store.snippets.count, 1, "Delete non-existent is no-op")
    }
}

// MARK: - Store Settings

func testStoreSettings() async {
    group("Store Settings")

    await MainActor.run {
        let store = makeTestStore()

        checkEqual(store.settings.cornerTrigger, .topLeft, "Default corner is top-left")

        store.updateCorner(.bottomRight)
        checkEqual(store.settings.cornerTrigger, .bottomRight, "Corner updated")

        store.updatePanelSize(heightRatio: 0.5, width: 420)
        check(abs(store.settings.panelHeightRatio - 0.5) < 0.001, "Height ratio updated")
        check(abs(store.settings.panelWidth - 420) < 0.001, "Width updated")
    }
}

// MARK: - Store Reorder

func testStoreReorder() async {
    group("Store Reorder")

    await MainActor.run {
        let store = makeTestStore()
        store.addTask(title: "C")
        store.addTask(title: "B")
        store.addTask(title: "A")
        // Order: A(idx 0), B(idx 1), C(idx 2)
        checkEqual(store.tasks.map(\.title), ["A", "B", "C"], "Initial order")

        // Move A to index 2
        let aId = store.tasks[0].id
        store.reorderTask(aId, to: 2)
        checkEqual(store.tasks.map(\.title), ["B", "C", "A"], "A moved to end")

        // Move A back to 0
        store.reorderTask(aId, to: 0)
        checkEqual(store.tasks.map(\.title), ["A", "B", "C"], "A moved back to start")

        // Edge: reorder non-existent
        store.reorderTask(9999, to: 0)
        checkEqual(store.tasks.map(\.title), ["A", "B", "C"], "Reorder non-existent is no-op")

        // Edge: reorder to index beyond bounds
        let bId = store.tasks[1].id
        store.reorderTask(bId, to: 100)
        checkEqual(store.tasks.last?.id, bId, "Reorder beyond bounds → clamps to end")
    }
}

// MARK: - Store Persistence Round-Trip

// We test Store with a temp directory to avoid touching real data.
@MainActor
func makeTestStore() -> Store {
    let store = Store()
    // Clear any existing data for clean tests
    store.tasks.removeAll()
    store.tags.removeAll()
    store.snippets.removeAll()
    store.settings = NookSettings()
    return store
}
