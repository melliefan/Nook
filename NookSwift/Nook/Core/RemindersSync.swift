import EventKit
import Foundation
import SwiftUI

/// One-way sync from Nook → Apple Reminders.
///
/// Why Reminders (not Calendar events):
/// - Reminders has a native completed state (matches Nook's task model)
/// - Reminders show in Calendar.app (toggle "Show Reminders") and on iOS Calendar
/// - One source of truth on the Apple side, syncs via iCloud automatically
///
/// Sync rules (locked in v1):
/// - Only tasks with `dueDate` are synced (Calendar requires a date)
/// - Direction is one-way: Nook → Reminders. Edits on the Reminders side don't
///   come back. We never mutate reminders not created by Nook.
/// - Completed tasks → reminder is marked complete (not deleted), preserving history
/// - Deleted tasks → matching reminder removed
/// - List name fixed: "Nook"
@MainActor
final class RemindersSync: ObservableObject {

    enum Status: Equatable {
        case disabled
        case unauthorized           // user denied or never asked
        case syncing
        case synced(count: Int)     // last successful sync wrote N reminders
        case error(String)
    }

    @Published var status: Status = .disabled

    private let store = EKEventStore()
    private let listName = "Nook"
    /// taskId → EKReminder.calendarItemExternalIdentifier. Persists across launches
    /// so we can find/update existing reminders rather than duplicate.
    private static let mapKey = "nook_reminders_map"
    private var taskToReminder: [Int: String] {
        get {
            (UserDefaults.standard.dictionary(forKey: Self.mapKey) as? [String: String] ?? [:])
                .reduce(into: [Int: String]()) { acc, kv in
                    if let id = Int(kv.key) { acc[id] = kv.value }
                }
        }
        set {
            let stringKeyed = newValue.reduce(into: [String: String]()) { acc, kv in
                acc[String(kv.key)] = kv.value
            }
            UserDefaults.standard.set(stringKeyed, forKey: Self.mapKey)
        }
    }

    /// Pending sync work — debounced so rapid mutations don't spam EventKit.
    private var pendingSyncWorkItem: DispatchWorkItem?

    // MARK: - Public API

    /// Probe current authorization without requesting.
    func refreshAuthorizationStatus() {
        if isEnabled {
            switch EKEventStore.authorizationStatus(for: .reminder) {
            case .authorized, .fullAccess:
                if case .synced = status { return }
                if case .syncing = status { return }
                status = .synced(count: taskToReminder.count)
            case .denied, .restricted:
                status = .unauthorized
            case .notDetermined, .writeOnly:
                status = .unauthorized
            @unknown default:
                status = .unauthorized
            }
        } else {
            status = .disabled
        }
    }

    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "nook_reminders_sync")
    }

    /// Turn on sync — request permission, do a full sync.
    func enable(allTasks: [NookTask]) async {
        UserDefaults.standard.set(true, forKey: "nook_reminders_sync")
        do {
            let granted = try await requestAccess()
            if !granted {
                status = .unauthorized
                return
            }
            await fullSync(tasks: allTasks)
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    /// Turn off sync — leave existing reminders alone, just stop new syncs.
    func disable() {
        UserDefaults.standard.set(false, forKey: "nook_reminders_sync")
        pendingSyncWorkItem?.cancel()
        status = .disabled
    }

    /// Debounced full sync — call after any store mutation. Coalesces rapid
    /// changes (e.g. typing in the task editor triggers many @Published updates)
    /// into a single sync 500ms after the last one.
    func scheduleSync(allTasks: [NookTask]) {
        guard isEnabled, isAuthorized else { return }
        pendingSyncWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                await self?.fullSync(tasks: allTasks)
            }
        }
        pendingSyncWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
    }

    /// Re-sync all currently active tasks (sets status to .synced or .error).
    /// Also cleans up "orphan" reminders — ones whose task was deleted from Nook.
    func fullSync(tasks: [NookTask]) async {
        guard isEnabled else { status = .disabled; return }
        guard isAuthorized else { status = .unauthorized; return }
        status = .syncing
        do {
            let calendar = try ensureNookCalendar()

            // 1. Orphan cleanup — remove reminders for tasks that no longer exist
            let currentIds = Set(tasks.map { $0.id })
            var map = taskToReminder
            for (taskId, externalId) in map where !currentIds.contains(taskId) {
                if let reminder = findReminder(externalId: externalId) {
                    try? store.remove(reminder, commit: false)
                }
                map.removeValue(forKey: taskId)
            }
            taskToReminder = map

            // 2. Upsert all tasks with dueDate
            var written = 0
            for task in tasks where task.dueDate != nil {
                try await upsertSync(task: task, in: calendar)
                written += 1
            }
            try store.commit()
            status = .synced(count: written)
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    // MARK: - Internals

    private var isAuthorized: Bool {
        let s = EKEventStore.authorizationStatus(for: .reminder)
        return s == .authorized || s == .fullAccess
    }

    private func requestAccess() async throws -> Bool {
        if #available(macOS 14.0, *) {
            return try await store.requestFullAccessToReminders()
        }
        return try await withCheckedThrowingContinuation { cont in
            store.requestAccess(to: .reminder) { granted, error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: granted) }
            }
        }
    }

    /// Find existing "Nook" reminders calendar; create if missing.
    private func ensureNookCalendar() throws -> EKCalendar {
        let calendars = store.calendars(for: .reminder)
        if let existing = calendars.first(where: { $0.title == listName }) {
            return existing
        }
        let new = EKCalendar(for: .reminder, eventStore: store)
        new.title = listName
        // Pick a sensible source — prefer iCloud for cross-device sync,
        // fall back to local.
        let sources = store.sources
        if let icloud = sources.first(where: { $0.sourceType == .calDAV && $0.title == "iCloud" }) {
            new.source = icloud
        } else if let local = sources.first(where: { $0.sourceType == .local }) {
            new.source = local
        } else if let any = sources.first {
            new.source = any
        }
        try store.saveCalendar(new, commit: true)
        return new
    }

    /// Create or update the reminder representing `task`.
    private func upsertSync(task: NookTask, in calendar: EKCalendar) async throws {
        let reminder: EKReminder
        if let externalId = taskToReminder[task.id], let existing = findReminder(externalId: externalId) {
            reminder = existing
        } else {
            reminder = EKReminder(eventStore: store)
            reminder.calendar = calendar
        }
        reminder.title = task.title
        reminder.notes = remindersNotes(for: task)
        reminder.priority = ekPriority(task.priority)
        reminder.isCompleted = task.completed
        if task.completed {
            reminder.completionDate = Date()
        } else {
            reminder.completionDate = nil
        }
        if let due = task.dueDate, let date = parseDate(due) {
            // All-day reminder: use noon UTC to avoid timezone drift across borders
            var comps = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
            comps.hour = 12; comps.minute = 0
            reminder.dueDateComponents = comps
        } else {
            reminder.dueDateComponents = nil
        }
        try store.save(reminder, commit: false)
        if reminder.calendarItemExternalIdentifier != nil {
            var map = taskToReminder
            map[task.id] = reminder.calendarItemExternalIdentifier
            taskToReminder = map
        }
    }

    private func findReminder(externalId: String) -> EKReminder? {
        let items = store.calendarItems(withExternalIdentifier: externalId)
        return items.compactMap { $0 as? EKReminder }.first
    }

    private func remindersNotes(for task: NookTask) -> String? {
        var parts: [String] = []
        if !task.description.isEmpty { parts.append(task.description) }
        if !task.subtasks.isEmpty {
            parts.append("")
            parts.append("子任务:")
            for s in task.subtasks {
                parts.append("  \(s.completed ? "✓" : "○") \(s.title)")
            }
        }
        if !task.tags.isEmpty {
            parts.append("")
            parts.append("Nook 标签: \(task.tags.joined(separator: ", "))")
        }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }

    private func ekPriority(_ p: NookTask.Priority) -> Int {
        // EKReminder priority: 0 = none, 1 = high, 5 = medium, 9 = low (matches RFC)
        switch p {
        case .high:   return 1
        case .medium: return 5
        case .low:    return 9
        case .none:   return 0
        }
    }

    private func parseDate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.date(from: s)
    }
}
