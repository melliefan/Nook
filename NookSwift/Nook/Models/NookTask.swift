import Foundation

struct Subtask: Codable, Identifiable, Equatable {
    var id: Int
    var title: String
    var completed: Bool
}

struct NookTask: Codable, Identifiable, Equatable {
    var id: Int
    var title: String
    var description: String
    var completed: Bool
    var priority: Priority
    var tags: [String]
    var subtasks: [Subtask]
    var nextSubId: Int
    var dueDate: String?
    var listId: String
    var createdAt: String
    var completedAt: String?

    enum Priority: String, Codable, CaseIterable {
        case high, medium, low, none
        var label: String {
            switch self {
            case .high: "高优先级"
            case .medium: "中优先级"
            case .low: "低优先级"
            case .none: "无优先级"
            }
        }
        var color: String {
            // macOS system color palette — matches HTML design tokens
            switch self {
            case .high: "#FF3B30"
            case .medium: "#FF9500"
            case .low: "#34C759"
            case .none: "#8E8E93"
            }
        }
        var order: Int {
            switch self {
            case .high: 0
            case .medium: 1
            case .low: 2
            case .none: 3
            }
        }
    }

    var isOverdue: Bool {
        guard let due = dueDate, !completed else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: due) else { return false }
        return Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }

    var formattedDueDate: String? {
        guard let due = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: due) else { return nil }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: date)
        let diff = cal.dateComponents([.day], from: today, to: target).day ?? 0
        switch diff {
        case 0: return "今天"
        case 1: return "明天"
        case -1: return "昨天"
        case ..<(-1): return "\(abs(diff))天前"
        case 2...7: return "\(diff)天后"
        default:
            let f = DateFormatter()
            f.dateFormat = "M月d日"
            return f.string(from: date)
        }
    }
}
