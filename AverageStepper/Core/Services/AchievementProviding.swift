import Foundation

/// Evaluates unlocks from local history (MVP: rule-based, expandable via `BadgeCatalog`).
protocol AchievementProviding: Sendable {
    func achievements(from history: [WalkSession], asOf date: Date) -> [Achievement]
    func newlyUnlocked(from old: [Achievement], to new: [Achievement]) -> [Achievement]
}
