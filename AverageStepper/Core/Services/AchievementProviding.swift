import Foundation

/// Evaluates streaks and unlocks from local history (MVP: in-memory).
protocol AchievementProviding: Sendable {
    func achievements(from history: [WalkSession]) -> [Achievement]
    func newlyUnlocked(from old: [Achievement], to new: [Achievement]) -> [Achievement]
}
