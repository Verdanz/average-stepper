import Foundation

/// User-visible achievement state (unlocked or locked).
struct Achievement: Identifiable, Equatable, Sendable {
    var id: String
    var badge: Badge
    var unlockedAt: Date?
    /// When locked, progress toward the next unlock (0...1). Nil if not tracked.
    var progress01: Double?

    var isUnlocked: Bool { unlockedAt != nil }

    init(id: String, badge: Badge, unlockedAt: Date? = nil, progress01: Double? = nil) {
        self.id = id
        self.badge = badge
        self.unlockedAt = unlockedAt
        self.progress01 = progress01
    }
}
