import Foundation

/// Static catalog entry for a badge (definition).
struct Badge: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var detail: String
    var systemImageName: String?

    init(id: String, title: String, detail: String, systemImageName: String? = nil) {
        self.id = id
        self.title = title
        self.detail = detail
        self.systemImageName = systemImageName
    }
}
