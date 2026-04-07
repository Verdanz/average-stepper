import Foundation
import Observation

@Observable
@MainActor
final class WalkCompleteViewModel {
    let session: WalkSession
    let newAchievements: [Achievement]
    let streakBefore: Int
    let streakAfter: Int
    let longestStreak: Int
    let lifetimeTotals: GamificationTotals
    let encouragement: String

    init(session: WalkSession, dependencies: AppDependencies) {
        self.session = session
        let engine = dependencies.achievementEngine
        let history = dependencies.walkHistory
        let beforeHistory = Array(history.dropLast())

        let now = Date()
        let beforeCtx = GamificationContext.make(history: beforeHistory, now: now)
        let afterCtx = GamificationContext.make(history: history, now: now)
        self.streakBefore = beforeCtx.streaks.current
        self.streakAfter = afterCtx.streaks.current
        self.longestStreak = afterCtx.streaks.longest
        self.lifetimeTotals = afterCtx.totals

        let before = engine.achievements(from: beforeHistory, asOf: now)
        let after = engine.achievements(from: history, asOf: now)
        let unlocked = engine.newlyUnlocked(from: before, to: after)
        self.newAchievements = unlocked

        self.encouragement = Self.encouragementLine(
            session: session,
            streakBefore: beforeCtx.streaks.current,
            streakAfter: afterCtx.streaks.current,
            newBadgeCount: unlocked.count
        )
    }

    private static func encouragementLine(
        session: WalkSession,
        streakBefore: Int,
        streakAfter: Int,
        newBadgeCount: Int
    ) -> String {
        if newBadgeCount > 0 {
            return "New milestones unlocked — carry that energy forward."
        }
        if streakAfter > streakBefore {
            return "Your walking rhythm is building. Stay with it."
        }
        switch session.completionReason {
        case .routeCompleted:
            return "You finished what you mapped. Steady focus, real progress."
        case .reachedStepGoal:
            return "You hit your target. Consistency compounds."
        case .userEnded, .aborted, .none:
            return "Movement counts. See you on the next walk."
        }
    }
}
