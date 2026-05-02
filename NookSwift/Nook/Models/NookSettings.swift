import Foundation

struct NookSettings: Codable, Equatable {
    var cornerTrigger: CornerTrigger
    var panelHeightRatio: Double
    var panelWidth: Double

    enum CornerTrigger: String, Codable, CaseIterable {
        case topLeft = "top-left"
        case topRight = "top-right"
        case bottomLeft = "bottom-left"
        case bottomRight = "bottom-right"

        var label: String {
            switch self {
            case .topLeft: "左上"
            case .topRight: "右上"
            case .bottomLeft: "左下"
            case .bottomRight: "右下"
            }
        }

        var isRight: Bool { self == .topRight || self == .bottomRight }
        var isBottom: Bool { self == .bottomLeft || self == .bottomRight }
    }

    init(cornerTrigger: CornerTrigger = .topLeft, panelHeightRatio: Double = 0.75, panelWidth: Double = 380) {
        self.cornerTrigger = cornerTrigger
        self.panelHeightRatio = panelHeightRatio
        self.panelWidth = panelWidth
    }
}
