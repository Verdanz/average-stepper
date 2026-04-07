import Foundation

/// User-visible achievement state (unlocked or locked).
struct Achievement: Identifiable, Equatable, Sendable {
    var id: String
    var badge: Badge
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }

    init(id: String, badge: Badge, unlockedAt: Date? = nil) {
        self.id = id
        self.badge = badge
        self.unlockedAt = unlockedAt
    }
}
