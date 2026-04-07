import Foundation

/// Evaluates `BadgeCatalog` rules against local walk history.
struct AchievementEngine: AchievementProviding {
    func achievements(from history: [WalkSession], asOf date: Date) -> [Achievement] {
        let context = GamificationContext.make(history: history, calendar: .autoupdatingCurrent, now: date)
        return BadgeCatalog.all.map { definition in
            let unlocked = AchievementRuleEvaluator.unlockDate(definition: definition, context: context)
            let progress: Double?
            if unlocked != nil {
                progress = nil
            } else {
                let p = AchievementRuleEvaluator.progressFraction(definition: definition, context: context)
                progress = p
            }
            return Achievement(
                id: definition.id,
                badge: definition.badge,
                unlockedAt: unlocked,
                progress01: progress
            )
        }
    }

    func newlyUnlocked(from old: [Achievement], to new: [Achievement]) -> [Achievement] {
        let oldUnlockedIds = Set(old.filter(\.isUnlocked).map(\.id))
        return new.filter { $0.isUnlocked && !oldUnlockedIds.contains($0.id) }
    }
}
