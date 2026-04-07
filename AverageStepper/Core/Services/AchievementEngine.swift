import Foundation

/// Rule-based badge evaluation. Replace with data-driven rules or persistence later.
struct AchievementEngine: AchievementProviding {
    func achievements(from history: [WalkSession]) -> [Achievement] {
        let definitions = MockData.allBadgeDefinitions
        let completed = history.filter { $0.status == .completed }

        return definitions.map { definition in
            let unlocked = unlockDate(for: definition.id, completedSessions: completed)
            return Achievement(
                id: definition.id,
                badge: definition,
                unlockedAt: unlocked
            )
        }
    }

    func newlyUnlocked(from old: [Achievement], to new: [Achievement]) -> [Achievement] {
        let oldIds = Set(old.filter(\.isUnlocked).map(\.id))
        return new.filter { $0.isUnlocked && !oldIds.contains($0.id) }
    }

    private func unlockDate(for id: String, completedSessions: [WalkSession]) -> Date? {
        switch id {
        case "first_walk":
            return completedSessions.first?.endedAt ?? completedSessions.first?.startedAt
        case "target_5k":
            return completedSessions.first(where: { $0.goal.targetSteps >= 5000 })?.endedAt
        case "target_10k":
            return completedSessions.first(where: { $0.goal.targetSteps >= 10_000 })?.endedAt
        default:
            // TODO: Implement streak_7, streak_30, walker_10 from dated history.
            return nil
        }
    }
}
