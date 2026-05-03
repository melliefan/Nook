import AppKit
import Foundation

/// RFC 5545 VCALENDAR generator for Nook tasks.
/// Each task with a `dueDate` becomes an all-day VEVENT — universal across
/// Calendar.app / Google Calendar / Outlook / Fantastical etc.
///
/// Tasks without `dueDate` are skipped (Calendar entries require a date).
enum ICSExporter {
    /// Build a VCALENDAR string from one or more tasks. Returns nil if none
    /// of the input tasks have a `dueDate`.
    static func makeICS(tasks: [NookTask]) -> String? {
        let usable = tasks.filter { $0.dueDate != nil }
        guard !usable.isEmpty else { return nil }

        var lines: [String] = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//Nook//Nook Mac App//EN",
            "CALSCALE:GREGORIAN",
        ]
        let stamp = utcStamp(Date())
        for task in usable {
            lines.append(contentsOf: vevent(for: task, stamp: stamp))
        }
        lines.append("END:VCALENDAR")
        // RFC 5545 says CRLF line endings.
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    /// Save panel + write file + open in default Calendar app.
    /// Returns the saved file URL (or nil if user cancelled / no usable tasks).
    @MainActor
    static func exportAndOpen(tasks: [NookTask]) -> URL? {
        guard let ics = makeICS(tasks: tasks) else { return nil }
        let panel = NSSavePanel()
        panel.title = "导出到日历"
        panel.allowedContentTypes = []   // .ics not in UTType registry, just trust nameField
        panel.nameFieldStringValue = tasks.count == 1
            ? "\(tasks[0].title).ics"
            : "Nook 任务 (\(tasks.count) 个).ics"
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        do {
            try ics.write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(url)
            return url
        } catch {
            print("[ICSExporter] write failed: \(error)")
            return nil
        }
    }

    // MARK: - Helpers

    private static func vevent(for task: NookTask, stamp: String) -> [String] {
        guard let due = task.dueDate, let date = parseDate(due) else { return [] }
        let dtStart = dateOnlyStamp(date)
        let dtEnd = dateOnlyStamp(date.addingTimeInterval(86400))   // RFC: DTEND = next day for all-day

        var summary = task.title
        if task.completed { summary = "✓ " + summary }
        summary = escape(summary)

        var descParts: [String] = []
        if !task.description.isEmpty { descParts.append(task.description) }
        if !task.subtasks.isEmpty {
            descParts.append("子任务:")
            for s in task.subtasks {
                descParts.append("  \(s.completed ? "[x]" : "[ ]") \(s.title)")
            }
        }
        if !task.tags.isEmpty {
            descParts.append("标签: \(task.tags.joined(separator: ", "))")
        }
        let description = escape(descParts.joined(separator: "\n"))

        var event: [String] = [
            "BEGIN:VEVENT",
            "UID:nook-\(task.id)@local",
            "DTSTAMP:\(stamp)",
            "DTSTART;VALUE=DATE:\(dtStart)",
            "DTEND;VALUE=DATE:\(dtEnd)",
            "SUMMARY:\(summary)",
        ]
        if !description.isEmpty {
            event.append("DESCRIPTION:\(description)")
        }
        if !task.tags.isEmpty {
            event.append("CATEGORIES:\(escape(task.tags.joined(separator: ",")))")
        }
        if let prio = icalPriority(task.priority) {
            event.append("PRIORITY:\(prio)")
        }
        event.append("STATUS:\(task.completed ? "COMPLETED" : "CONFIRMED")")
        event.append(task.completed ? "TRANSP:TRANSPARENT" : "TRANSP:OPAQUE")
        event.append("END:VEVENT")
        return event
    }

    /// RFC 5545 PRIORITY: 0 = unset, 1-4 = high, 5 = medium, 6-9 = low
    private static func icalPriority(_ p: NookTask.Priority) -> String? {
        switch p {
        case .high:   return "1"
        case .medium: return "5"
        case .low:    return "9"
        case .none:   return nil
        }
    }

    private static func parseDate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.date(from: s)
    }

    private static func dateOnlyStamp(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.string(from: d)
    }

    private static func utcStamp(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.string(from: d)
    }

    /// Escape special chars per RFC 5545: backslash, semicolon, comma, newline.
    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
