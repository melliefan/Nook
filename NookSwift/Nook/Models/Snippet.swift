import Foundation

struct Snippet: Codable, Identifiable, Equatable {
    var id: Int
    var label: String
    var value: String
    var type: String
    var createdAt: String
}
